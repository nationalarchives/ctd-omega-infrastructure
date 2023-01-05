################################################################################
# GitHub OIDC Role
################################################################################
module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name = "IAMGitHubOIDCRole"
  subjects = [
    "repo:nationalarchives/ctd-omega-editorial-frontend:*"
  ]
  policies = {
    additional = aws_iam_policy.CodeDeployAccess.arn
    S3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }
}

################################################################################
# CodeDeploy Service Role
################################################################################
resource "aws_iam_role" "CodeDeployServiceRole" {
  name        = "CodeDeployServiceRole"
  description = "Allows CodeDeploy to call AWS services such as Auto Scaling on your behalf."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

################################################################################
# GitHub OIDC Provider
# Note: This is one per AWS account
################################################################################
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role_policy" "cd_role_policy" {
  name = "CodeDeployRole"
  role = aws_iam_role.CodeDeployServiceRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "CodeDeployAccessPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "codedeploy:*",
          "ec2:*",
          #"lambda:*",
          #"ecs:*",
          # There is probably a whole bunch here we don't need
          "elasticloadbalancing:*",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "s3:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid = "CodeDeployRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.CodeDeployServiceRole.arn
      }
    ]
  })
}

resource "aws_iam_policy" "CodeDeployAccess" {
  name = "CodeDeployAccess"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        #Sid = "CodeDeployAccessPolicy"
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "codedeploy:*",
          "ec2:*",
          #"lambda:*",
          #"ecs:*",
          # There is probably a whole bunch here we don't need
          "elasticloadbalancing:*",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetInstanceProfile",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "s3:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid = "CodeDeployRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.CodeDeployServiceRole.arn
      }
    ]
  })
}

################################################################################
# CodeDeploy EC2 Permissions
################################################################################
resource "aws_iam_policy" "code_deploy_ec2_permissions" {
  name = "CodeDeployEC2Permissions"
  description = "Gives access to ctd-omega-frontend-deployment S3 bucket"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:Get*",
          "s3:List*"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::ctd-omega-frontend-deployment/*",
          "arn:aws:s3:::aws-codedeploy-eu-west-2/*"
        ]
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "code_deploy_ec2_attach" {
  role = aws_iam_role.code_deploy_ec2_instance_profile_role.name
  policy_arn = aws_iam_policy.code_deploy_ec2_permissions.arn
}

################################################################################
# Enable EC2 instance to use AWS Systems Manager for Code Deploy
################################################################################
resource "aws_iam_role_policy_attachment" "code_deploy_ssm_attach" {
  role       = aws_iam_role.code_deploy_ec2_instance_profile_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployServiceRole.name
}

################################################################################
# CodeDeploy EC2 Instance Profile
################################################################################
resource "aws_iam_role" "code_deploy_ec2_instance_profile_role" {
  name = "CodeDeployEC2InstanceProfileRole"
  description = "Allows EC2 instances to call AWS services on your behalf."
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "code_deploy_ec2_profile" {
  name = "CodeDeployEC2Profile"
  role = aws_iam_role.code_deploy_ec2_instance_profile_role.name
}
