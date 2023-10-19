###
# Terraform Script for a Messaging Fabric in AWS Cloud for Omega
#
# Author: Adam Retter @ Evolved Binary
###

# TODO(AR) - restrict access to SQS from VPC endpoints only
# TODO(AR) - force SQS to only accept TLS connections
# TODO(AR) - IAM policy for the dead_letter_queue

# The Dead Letter Queue
resource "aws_sqs_queue" "dead_letter_queue" {
  name                       = "deadletter"
  delay_seconds              = 0
  max_message_size           = 262144     # 256KB
  message_retention_seconds  = 1209600    # 14 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
  sqs_managed_sse_enabled    = true
  
  redrive_allow_policy = jsonencode({
    redrivePermission = "allowAll"
  })

  tags = {
    Type        = "sqs_queue"
    Direction   = "dead_letter"
    Priority    = "none"
    Environment = "mvpbeta"
  }
}

# The 'PACS001_REQUEST001' queue
resource "aws_sqs_queue" "pacs001_request001" {
  name                       = "PACS001_REQUEST001"
  delay_seconds              = 0
  max_message_size           = 1024     # 1KB
  message_retention_seconds  = 1209600	# 14 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })

  tags = {
    Type        = "sqs_queue"
    Direction   = "request"
    Priority    = "general"
    Environment = "mvpbeta"
  }
}

# The 'PACE001_REPLY001' queue
resource "aws_sqs_queue" "pace001_reply001" {
  name                       = "PACE001_REPLY001"
  delay_seconds              = 0
  max_message_size           = 1024     # 1KB
  message_retention_seconds  = 1209600	# 14 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 30
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 3
  })

  tags = {
    Type        = "sqs_queue"
    Direction   = "reply"
    Priority    = "general"
    Environment = "mvpbeta"
  }
}


# TODO(AR) restrict "Principal": "*" to who is allowed to actually access this - IAM accounts/roles?

# TODO(AR) add a 'Condition' to restrict the source to the web-app-1 (or my dev-1) e.g.
## "ArnEquals": {											
##     "aws:SourceArn": "${aws_sns_topic.example.arn}"
## }

resource "aws_sqs_queue_policy" "dead_letter_queue_policy" {
  queue_url = aws_sqs_queue.dead_letter_queue_policy.id
  policy    = data.aws_iam_policy_document.dead_letter_queue_policy.json
}

# Allow Sending messages to queue `PACS001_REQUEST001` by `web-app-1` and dev workstations
data "aws_iam_policy_document" "dead_letter_queue_policy" {
    statement {
        sid = "First"
        effect = "Allow"

        actions   = ["sqs:ReceiveMessage"]

        principals {
            type        = "*"
            # identifiers = ["*"]
            identifiers = [
                # TODO(AR) use a loop to produce this
                module.ec2_instance["dev_workstation_1"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_2"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_3"].ec2_instance_arn
            ]
        }

        resources = [aws_sqs_queue.dead_letter_queue.arn]

        condition {
            test = "Bool"
            variable = "aws:SecureTransport"
            values = ["true"]
        }
    }
}

resource "aws_sqs_queue_policy" "pacs001_request001_send_policy" {
  queue_url = aws_sqs_queue.pacs001_request001.id
  policy    = data.aws_iam_policy_document.pacs001_request001_send_policy.json
}

# Allow Sending messages to queue `PACS001_REQUEST001` by `web-app-1` and dev workstations
data "aws_iam_policy_document" "pacs001_request001_send_policy" {
    statement {
        sid = "First"
        effect = "Allow"

        actions   = ["sqs:SendMessage"]

        principals {
            type        = "*"
            # identifiers = ["*"]
            identifiers = [
                module.ec2_instance["web_app_1"].ec2_instance_arn,

                # TODO(AR) use a loop to produce this
                module.ec2_instance["dev_workstation_1"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_2"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_3"].ec2_instance_arn
            ]
        }

        resources = [aws_sqs_queue.pacs001_request001.arn]

        condition {
            test = "Bool"
            variable = "aws:SecureTransport"
            values = ["true"]
        }
    }
}

resource "aws_sqs_queue_policy" "pacs001_request001_receive_policy" {
  queue_url = aws_sqs_queue.pacs001_request001.id
  policy    = data.aws_iam_policy_document.pacs001_request001_receive_policy.json
}

# Allow Receiving messages from queue `PACS001_REQUEST001` by `services-api-1` and dev workstations
data "aws_iam_policy_document" "pacs001_request001_receive_policy" {
    statement {
        sid = "First"
        effect = "Allow"

        actions   = ["sqs:ReceiveMessage"]

        principals {
            type        = "*"
            # identifiers = ["*"]
            identifiers = [
                module.ec2_instance["services_api_1"].ec2_instance_arn,

                # TODO(AR) use a loop to produce this
                module.ec2_instance["dev_workstation_1"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_2"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_3"].ec2_instance_arn
            ]
        }

        resources = [aws_sqs_queue.pacs001_request001.arn]

        condition {
            test = "Bool"
            variable = "aws:SecureTransport"
            values = ["true"]
        }
    }
}

resource "aws_sqs_queue_policy" "pace001_reply001_send_policy" {
  queue_url = aws_sqs_queue.pace001_reply001.id
  policy    = data.aws_iam_policy_document.pace001_reply001_send_policy.json
}

# Allow Sending messages to queue `PACE001_REPLY001` by `services-api-1` and dev workstations
data "aws_iam_policy_document" "pace001_reply001_send_policy" {
    statement {
        sid = "First"
        effect = "Allow"

        actions   = ["sqs:SendMessage"]

        principals {
            type        = "*"
            # identifiers = ["*"]
            identifiers = [
                module.ec2_instance["services_api_1"].ec2_instance_arn,

                # TODO(AR) use a loop to produce this
                module.ec2_instance["dev_workstation_1"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_2"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_3"].ec2_instance_arn
            ]
        }

        resources = [aws_sqs_queue.pace001_reply001.arn]

        condition {
            test = "Bool"
            variable = "aws:SecureTransport"
            values = ["true"]
        }
    }
}

resource "aws_sqs_queue_policy" "pace001_reply001_receive_policy" {
  queue_url = aws_sqs_queue.pace001_reply001.id
  policy    = data.aws_iam_policy_document.pace001_reply001_receive_policy.json
}

# Allow Receiving messages from queue `PACE001_REPLY001` by `web-app-1` and dev workstations
data "aws_iam_policy_document" "pace001_reply001_receive_policy" {
    statement {
        sid = "First"
        effect = "Allow"

        actions   = ["sqs:ReceiveMessage"]

        principals {
            type        = "*"
            # identifiers = ["*"]
            identifiers = [
                module.ec2_instance["services_api_1"].ec2_instance_arn,

                # TODO(AR) use a loop to produce this
                module.ec2_instance["dev_workstation_1"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_2"].ec2_instance_arn,
                module.ec2_instance["dev_workstation_3"].ec2_instance_arn
            ]
        }

        resources = [aws_sqs_queue.pace001_reply001.arn]

        condition {
            test = "Bool"
            variable = "aws:SecureTransport"
            values = ["true"]
        }
    }
}
