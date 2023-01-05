### CodeDeploy Config ###

resource "aws_codedeploy_app" "CtdOmegaEditorialFrontend" {
  name = "CtdOmegaEditorialFrontend"
}

resource "aws_codedeploy_deployment_group" "CtdOmegaEditorialFrontend-DepGrp" {
  app_name               = aws_codedeploy_app.CtdOmegaEditorialFrontend.name
  deployment_group_name  = "CtdOmegaEditorialFrontend-DepGrp"
  service_role_arn       = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "EditorialWeb"
    }

  }

  /*
  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "example-trigger"
    trigger_target_arn = aws_sns_topic.example.arn
  }
  */

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }
}




