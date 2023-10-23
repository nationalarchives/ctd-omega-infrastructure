## A Simple scheduler executed via AWS Lambda
## The scheduler will start and stop any EC2 instance that has the tag `scheduler_mon_fri_dev_ec2 = "true"`
## Current Schedule is set to:
##  1. Stop any active instances (with the tag) at 21:00 UTC Monday to Sunday
##  2. Start any inactive instances (with the tag) at 07:00 UTC Monday to Sunday
##
## This is predominantly envisaged to be used for the Development Environment systems to save costs when they are not in use by staff.

module "scheduler_mon_fri_stop_ec2" {
  source                         = "diodonfrost/lambda-scheduler-stop-start/aws"
  version                        = "3.5.0"
  name                           = "ec2_stop"
  cloudwatch_schedule_expression = "cron(0 21 ? * MON-SUN *)"
  schedule_action                = "stop"
  autoscaling_schedule           = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  cloudwatch_alarm_schedule      = "false"

  scheduler_tag = {
    key   = "scheduler_mon_fri_ec2"
    value = "true"
  }
}

module "scheduler_mon_fri_start_ec2" {
  source                         = "diodonfrost/lambda-scheduler-stop-start/aws"
  version                        = "3.5.0"
  name                           = "ec2_start"
  cloudwatch_schedule_expression = "cron(0 8 ? * MON-FRI *)"
  schedule_action                = "start"
  autoscaling_schedule           = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  cloudwatch_alarm_schedule      = "false"

  scheduler_tag = {
    key   = "scheduler_mon_fri_ec2"
    value = "true"
  }
}
