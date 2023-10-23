# resource "aws_iam_service_linked_role" "neptune_service_linked_role" {
#   aws_service_name = "rds.amazonaws.com"  // TODO(AR) should this be 'neptune.amazonaws.com'?
# }

resource "aws_iam_role" "neptune_service_role" {
  name               = "NeptuneServiceLinked"
  assume_role_policy = data.aws_iam_policy_document.neptune_service_assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole",
    aws_iam_policy.neptune_service_role_policy.arn
  ]
}

data "aws_iam_policy_document" "neptune_service_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"] // TODO(AR) should this be 'neptune.amazonaws.com'?
    }
  }
}

resource "aws_iam_policy" "neptune_service_role_policy" {
  name   = "neptune_service_role_policy"
  path   = "/neptune/"
  policy = data.aws_iam_policy_document.neptune_service_role_policy.json
}

data "aws_iam_policy_document" "neptune_service_role_policy" {
  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "rds.amazonaws.com" // TODO(AR) should this be 'neptune.amazonaws.com'?
      ]
    }
  }
}


# Create neptune user

resource "aws_iam_user" "neptune_user" {
  name = "neptune_user"
  path = "/neptune/"
}

resource "aws_iam_access_key" "neptune_user" {
  user = aws_iam_user.neptune_user.name
}

resource "aws_iam_user_policy" "neptune_user_rw" {
  name = "neptuneuserpolicy"
  user = aws_iam_user.neptune_user.name

  policy = data.aws_iam_policy_document.neptune_user_rw_policy.json
}

data "aws_iam_policy_document" "neptune_user_rw_policy" {
  statement {
    actions = [
      # aws_iam_role.neptune_service_role.name,  // TODO(AR) should this also go in here?
      "iam:AmazonVPCFullAccess",
      "iam:NeptuneFullAccess",
      "iam:NeptuneConsoleFullAccess"
    ]

    resources = [
      "*"
    ]
  }
}
