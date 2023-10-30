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


resource "aws_iam_policy" "neptune_sparql_read_write_policy" {
  name        = "neptune_sparql_read_write_policy"
  path        = "/neptune/"
  description = "SPARQL Read-Write policy"

  policy = data.aws_iam_policy_document.neptune_sparql_read_write_policy.json
}

resource "aws_iam_policy" "neptune_sparql_read_only_policy" {
  name        = "neptune_sparql_read_only_policy"
  path        = "/neptune/"
  description = "SPARQL Read-only policy"

  policy = data.aws_iam_policy_document.neptune_sparql_read_only_policy.json
}

resource "aws_iam_policy" "neptune_sparql_write_only_policy" {
  name        = "neptune_sparql_write_only_policy"
  path        = "/neptune/"
  description = "SPARQL Write-only policy"

  policy = data.aws_iam_policy_document.neptune_sparql_write_only_policy.json
}

# Neptune Read-Write SPARQL Query Policy
data "aws_iam_policy_document" "neptune_sparql_read_write_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.neptune_sparql_read_only_policy.json,
    data.aws_iam_policy_document.neptune_sparql_write_only_policy.json,
  ]
}

# Neptune Read Only SPARQL Query Policy
data "aws_iam_policy_document" "neptune_sparql_read_only_policy" {
    statement {
      actions = [
        "neptune-db:ReadDataViaQuery",
        "neptune-db:GetQueryStatus"
      ]

      resources = [
        "arn:aws:neptune-db:${local.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_neptune_cluster.dev_neptune_cluster_a.cluster_resource_id}/*"
      ]

      condition {
        test = "StringEquals"
        variable = "neptune-db:QueryLanguage"
        values = ["Sparql"]
      }
    }
}

# Neptune Write Only SPARQL Query Policy
data "aws_iam_policy_document" "neptune_sparql_write_only_policy" {
    statement {
      actions = [
        "neptune-db:WriteDataViaQuery",
        "neptune-db:GetQueryStatus"
      ]

      resources = [
        "arn:aws:neptune-db:${local.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_neptune_cluster.dev_neptune_cluster_a.cluster_resource_id}/*"
      ]

      condition {
        test = "StringEquals"
        variable = "neptune-db:QueryLanguage"
        values = ["Sparql"]
      }
    }
}
