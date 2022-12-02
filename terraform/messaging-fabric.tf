###
# Terraform Script for a Messaging Fabric in AWS Cloud for Omega
#
# Author: Adam Retter @ Evolved Binary
###

# TODO(AR) - restrict access to SQS from VPC endpoints only
# TODO(AR) - force SQS to only accept TLS connections
# TODO(AR) - IAM policy for the dead_letter_queue

resource "aws_sqs_queue" "dead_letter_queue" {
  name                       = "deadletter"
  delay_seconds              = 0
  max_message_size           = 262144  # 256KB
  message_retention_seconds  = 1209600 # 14 days
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

resource "aws_sqs_queue" "request_general_queue" {
  name                       = "request_general"
  delay_seconds              = 0
  max_message_size           = 1024    # 1KB
  message_retention_seconds  = 1209600 # 14 days
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


# TODO(AR) restrict "Principal": "*" to who is allowed to actually access this - IAM accounts/roles?

# TODO(AR) add a 'Condition' to restrict the source to the web-app-1 (or my dev-1) e.g.
## "ArnEquals": {											
##     "aws:SourceArn": "${aws_sns_topic.example.arn}"
## }

resource "aws_sqs_queue_policy" "request_general_queue_policy" {
  queue_url = aws_sqs_queue.request_general_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",											
      "Action": [
        "sqs:SendMessage",
      	"sqs:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.request_general_queue.arn}",
      "Condition": {
      	"Bool": {
      		"aws:SecureTransport": "true"
  		}
      }
    }
  ]
}
POLICY
}
