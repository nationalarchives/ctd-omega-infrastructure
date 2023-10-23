resource "aws_iam_policy" "puppet_server_access_secrets_iam_policy" {
  name   = "puppet_server_access_secrets_iam_policy"
  path   = "/puppet/"
  policy = data.aws_iam_policy_document.puppet_server_access_secrets_iam_policy.json
}

data "aws_iam_policy_document" "puppet_server_access_secrets_iam_policy" {
  statement {
    sid = "PuppetServerAccessSecrets"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      aws_secretsmanager_secret.dev_mssql_server_1_sa_password_secret.arn
    ]
  }

  statement {
    sid = "PuppetServerListAllSecrets"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = [
      "*"
    ]
  }
}
