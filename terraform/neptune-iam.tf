################################################################################
# Create a service-linked role policy for Amazon Neptune
################################################################################
resource "aws_iam_service_linked_role" "neptune_service_linked_role" {
  aws_service_name = "neptune.amazonaws.com"
}

data "aws_iam_policy" "neptune_service_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "neptune_service_role_policy_attach" {
  role       = aws_iam_role.neptune_service_role.name
  policy_arn = data.aws_iam_policy.neptune_service_policy.arn
}

resource "aws_iam_role" "neptune_service_role" {
  name               = "NeptuneServiceLinked"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "iam:CreateServiceLinkedRole",
      "Effect": "Allow",
      "Resource": "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      "Condition": {
        "StringLike": {
            "iam:AWSServiceName":"rds.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}


################################################################################
# Create neptune user
################################################################################

resource "aws_iam_user" "neptuneuser" {
  name = "neptuneuser"
  path = "/neptune/"
}

resource "aws_iam_access_key" "lb" {
  user = aws_iam_user.neptuneuser.name
}

resource "aws_iam_user_policy" "neptuneuser_rw" {
  name = "neptuneuserpolicy"
  user = aws_iam_user.neptuneuser.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        ${aws_iam_role.neptune_service_role.name},
        "iam:AmazonVPCFullAccess",
        "iam:NeptuneFullAccess",
        "iam:NeptuneConsoleFullAccess"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
