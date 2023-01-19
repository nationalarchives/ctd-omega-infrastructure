data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  mappings = {
    RuntimeMap = {
      python3.9 = {
        keyname = "python39/release_2022_07_27"
      }
      java8 = {
        keyname = "java8"
      }
    }
    Gremlin = {
      python3.9 = {
        true = "neptune_to_es.neptune_gremlin_es_handler.ElasticSearchGremlinHandler"
        false = "neptune_to_es.neptune_gremlin_es_string_indexing_handler.ElasticSearchStringOnlyGremlinHandler"
      }
      java8 = {
        true = "com.amazonaws.neptune.ElasticsearchGremlinReplicationHandler"
        false = "com.amazonaws.neptune.ElasticsearchGremlinReplicationHandler"
      }
    }
    Sparql = {
      python3.9 = {
        true = "neptune_to_es.neptune_sparql_es_handler.ElasticSearchSparqlHandler"
        false = "neptune_to_es.neptune_sparql_es_string_indexing_handler.ElasticSearchStringOnlySparqlHandler"
      }
      java8 = {
        true = "com.amazonaws.neptune.ElasticsearchSparqlReplicationHandler"
        false = "com.amazonaws.neptune.ElasticsearchSparqlReplicationHandler"
      }
    }
    ReplicationScopeMap = {
      All = {
        keyname = "all"
      }
      Nodes = {
        keyname = "nodes"
      }
    }
  }
  CreateManagedPolicy = join(",", var.managed_policies) == ""
  IsEmptyLambdaS3Bucket = var.lambda_s3_bucket == ""
  IsEmptyLambdaS3Key = var.lambda_s3_key == ""
  IsEmptyStreamRecordsHandler = var.stream_records_handler == ""
  CreateCloudWatchAlarmCondition = var.create_cloud_watch_alarm == "true"
}

variable "application_name" {
  description = "Application Name used as a reference to create resources"
  type = string
  default = "NeptuneStream"
}

variable "lambda_memory_size" {
  description = "Poller Lambda  memory size (in MB). Should be one of 128 MB, 256 MB, 512 MB, 1024 MB, 2048 MB."
  type = string
  default = 2048
}

variable "lambda_runtime" {
  description = "Lambda Runtime"
  type = string
  default = "python3.9"
}

variable "lambda_s3_bucket" {
  description = "S3 bucket having Lambda Artifact. Optional Parameter - If left blank artifact will be picked from default Bucket."
  type = string
}

variable "lambda_s3_key" {
  description = "S3 key for Lambda Artifact. Optional Parameter - If left blank default Lambda Artifact is used."
  type = string
}

variable "lambda_logging_level" {
  description = "Poller Lambda logging level."
  type = string
  default = "INFO"
}

variable "managed_policies" {
  description = "Comma-delimited list of ARNs of managed policies to be attached to Lambda execution role. Optional Parameter - If left blank policy with required access is created. "
  type = string
}

variable "stream_records_handler" {
  description = "Handler for processing stream records. Optional Parameter - If left blank default Handler for Elastic Search is used."
  type = string
}

variable "stream_records_batch_size" {
  description = "Number of records to be read from stream in each batch. Should be between 1 to 50000."
  type = string
  default = 5000
}

variable "max_polling_wait_time" {
  description = "Maximum wait time in seconds between two successive polling from stream. Set value to 0 sec for continuous polling. Maximum value can be 3600 sec (1 hour)."
  type = string
  default = 60
}

variable "max_polling_interval" {
  description = "Period for which we can continuously poll stream for records on one Lambda instance. Should be between 5 sec to 900 sec. This parameter is used to set Poller Lambda Timeout."
  type = string
  default = 600
}

variable "neptune_stream_endpoint" {
  description = "Endpoint for source Neptune Stream. This is of the form http(s)://<cluster>:<port>/gremlin/stream or http(s)://<cluster>:<port>/sparql/stream."
  type = string
}

variable "query_engine" {
  description = "Neptune Query Engine."
  type = string
  default = "Gremlin"
}

variable "iam_auth_enabled_on_source_stream" {
  description = "Flag to determine if IAM Auth is Enabled for Source Neptune Cluster or not."
  type = string
  default = "false"
}

variable "stream_db_cluster_resource_id" {
  description = "Neptune DB Cluster Resource Id. Ex: cluster-5DSWZGISGVCHJPHOV5MK7QF2PY. Optional Parameter- Only needed when IAM Auth is Enabled."
  type = string
}

variable "step_function_fallback_period" {
  description = "Period after which Step function is invoked using Cloud Watch Events to recover from failure. Unit for Step Function Fallback period is set separately."
  type = string
  default = 5
}

variable "step_function_fallback_period_unit" {
  description = "Step Function FallbackPeriod unit. Should be one of minutes, minute, hours, hour, days, day"
  type = string
  default = "minutes"
}

variable "notification_sns_topic_arn" {
  description = "SNS Topic ARN where CloudWatch Alarm Notifications would be sent. Eg. arn:aws:sns:<region>:<account-id>:<name>. Optional."
  type = string
}

variable "notification_email" {
  description = "Email Address for CloudWatch Alarm Notification. Optional Parameter - Only needed when selecting option to create CloudWatch Alarm."
  type = string
}

variable "vpc" {
  description = "The VPC in which Neptune Stream Instance is present"
  type = string
}

variable "subnet_ids" {
  description = "The subnets to which a network interface is established. Add subnets associated with both Neptune Stream Cluster & Neptune target Cluster."
  type = string
}

variable "security_group_ids" {
  description = "The Security groups associated with the Neptune Stream Cluster and Neptune Target Cluster."
  type = string
}

variable "route_table_ids" {
  description = "Comma Delimited list of Route table ids associated with the Subnets. For Example: rtb-a12345,rtba7863k1. Optional parameter - Only needed when creating DynamoDB VPC Endpoint."
  type = string
}

variable "create_ddbvpc_end_point" {
  description = "Flag used to determine whether to create Dynamo DB VPC Endpoint or not. Select false only if Dynamo DB VPC endpoint already present."
  type = string
  default = "true"
}

variable "create_monitoring_end_point" {
  description = "Flag used to determine whether to create Monitoring VPC Endpoint or not. Select false only if Monitoring VPC endpoint already present."
  type = string
  default = "true"
}

variable "create_cloud_watch_alarm" {
  description = "Flag used to determine whether to create Cloud watch alarm or not."
  type = string
  default = "false"
}

variable "elastic_search_endpoint" {
  description = "Elastic Search Cluster Endpoint. Ex : vpc-neptunestream.us-east-1.es.amazonaws.com"
  type = string
}

variable "number_of_shards" {
  description = "Number of Shards for Elastic Search Index. Default value is 5."
  type = string
  default = 5
}

variable "number_of_replica" {
  description = "Number of replicas for Elastic Search Index. Default value is 1."
  type = string
  default = 1
}

variable "geo_location_fields" {
  description = "Comma Delimited list of Property Keys to be mapped to Geo Point Type in Elastic Search. For Example: location,area. Currently, for a field to be mapped to Geo Point type, value should be in the format 'latitude,longitude' Ex: '41.33,-11.69'"
  type = string
}

variable "properties_to_exclude" {
  description = "Comma delimited list of Property Keys to exclude from being indexed into Elastic Search. Optional Parameter - If left blank, all property keys will be indexed."
  type = string
}

variable "datatypes_to_exclude" {
  description = "Comma delimited list of Property Value Data Types to exclude from being indexed into Elastic Search. Optional Parameter - If left blank, all valid property values will be indexed. Type inputs that are unsupported for the specified query language will be ignored. Valid inputs for Sparql/RDF data: [string, boolean, float, double, dateTime, byte, int, long, short, date, decimal, integer, nonNegativeInteger, nonPositiveInteger, negativeInteger, unsignedByte, unsignedInt, unsignedLong, unsignedShort, time]. Valid inputs for Gremlin data: [string, date, bool, byte, short, int, long, float, double]"
  type = string
}

variable "enable_non_string_indexing" {
  description = "Flag to enable/disable indexing Non-String fields"
  type = string
  default = "true"
}

variable "replication_scope" {
  description = "Determines whether to replicate both nodes and edges, or only nodes (Gremlin engine only)."
  type = string
  default = "All"
}

variable "ignore_missing_document" {
  description = "Flag to determine if missing document error in Elastic Search can be ignored. Missing document error can occur rarely but will need manual intervention if not ignored."
  type = string
  default = "true"
}

resource "aws_api_gateway_rest_api_policy" "managed_policy" {
  count = locals.CreateManagedPolicy ? 1 : 0
  // CF Property(Description) = "Policy for Elastic Search Access for Neptune Lambda Poller"
  // CF Property(Path) = "/"
  policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "es:ESHttpDelete",
          "es:ESHttpGet",
          "es:ESHttpHead",
          "es:ESHttpPost",
          "es:ESHttpPut"
        ]
        Effect = "Allow"
        Resource = [
          "arn:${data.aws_partition.current.partition}:es:*:*:*"
        ]
      }
    ]
  }
}

resource "aws_cloudformation_stack" "neptune_stream_poller" {
  parameters = {
    AdditionalParams = "{ "ElasticSearchEndpoint": "${var.elastic_search_endpoint}", "NumberOfShards": "${var.number_of_shards}", "NumberOfReplica": "${var.number_of_replica}", "IgnoreMissingDocument": "${var.ignore_missing_document}", "ReplicationScope": "${local.mappings["ReplicationScopeMap"][var.replication_scope]["keyname"]}", "GeoLocationFields": "${var.geo_location_fields}", "DatatypesToExclude": "${var.datatypes_to_exclude}", "PropertiesToExclude": "${var.properties_to_exclude}", "EnableNonStringIndexing": "${var.enable_non_string_indexing}"}"
    ApplicationName = var.application_name
    LambdaMemorySize = var.lambda_memory_size
    LambdaRuntime = var.lambda_runtime
    LambdaS3Bucket = local.IsEmptyLambdaS3Bucket ? join("-", ["aws-neptune-customer-samples", data.aws_region.current.name]) : var.lambda_s3_bucket
    LambdaS3Key = local.IsEmptyLambdaS3Key ? join("/", ["neptune-stream", "lambda", local.mappings["RuntimeMap"][var.lambda_runtime]["keyname"], "neptune-to-es.zip"]) : var.lambda_s3_key
    ManagedPolicies = local.CreateManagedPolicy ? aws_api_gateway_rest_api_policy.managed_policy[0].id : join(",", var.managed_policies)
    LambdaLoggingLevel = var.lambda_logging_level
    StreamRecordsHandler = local.IsEmptyStreamRecordsHandler ? local.mappings[var.query_engine][var.lambda_runtime][var.enable_non_string_indexing] : var.stream_records_handler
    StreamRecordsBatchSize = var.stream_records_batch_size
    StepFunctionFallbackPeriod = var.step_function_fallback_period
    StepFunctionFallbackPeriodUnit = var.step_function_fallback_period_unit
    MaxPollingWaitTime = var.max_polling_wait_time
    NeptuneStreamEndpoint = var.neptune_stream_endpoint
    IAMAuthEnabledOnSourceStream = var.iam_auth_enabled_on_source_stream
    StreamDBClusterResourceId = var.stream_db_cluster_resource_id
    MaxPollingInterval = var.max_polling_interval
    VPC = var.vpc
    RouteTableIds = var.route_table_ids
    CreateDDBVPCEndPoint = var.create_ddbvpc_end_point
    CreateMonitoringEndPoint = var.create_monitoring_end_point
    CreateCloudWatchAlarm = var.create_cloud_watch_alarm
    NotificationSNSTopicArn = var.notification_sns_topic_arn
    NotificationEmail = var.notification_email
    SubnetIds = join(",", var.subnet_ids)
    SecurityGroupIds = join(",", var.security_group_ids)
  }
  template_url = "https://s3.amazonaws.com/aws-neptune-customer-samples/neptune-stream/neptune_stream_poller_nested_full_stack.json"
}

output "https_access_sg" {
  description = "HTTPS Access Security Group Arn"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.HTTPSAccessSG
}

output "lease_dynamo_db_table" {
  description = "Neptune Stream Poller Lease Table"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.LeaseDynamoDBTable
}

output "state_machine_arn" {
  description = "Neptune Stream Poller State Machine Arn"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.StateMachineArn
}

output "cron_arn" {
  description = "Neptune Stream Poller Scheduler Cron Arn"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.CronArn
}

output "state_machine_alarm_arn" {
  description = "Neptune Stream Poller State Machine Alarm Arn"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.StateMachineAlarmArn
}

output "neptune_stream_poller_lambda_arn" {
  description = "Neptune Stream Poller Lambda Arn"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.NeptuneStreamPollerLambdaArn
}

output "cloud_watch_metrics_dashboard_uri" {
  description = "CloudWatch Metrics Dashboard URI"
  value = aws_cloudformation_stack.neptune_stream_poller.outputs.CloudWatchMetricsDashboardURI
}
