
locals {
  CreateDBReplicaInstance = !var.db_replica_identifier_suffix == ""
  AZ3NotPresent = anytrue([data.aws_region.current.name == "ca-central-1", data.aws_region.current.name == "us-west-1"])
  AZ3Present = !local.AZ3NotPresent
  CreateEC2Instance = !var.ec2_client_instance_type == "none"
  CreateSagemakerNotebook = !var.notebook_instance_type == "none"
}

variable "ec2_ssh_key_pair_name" {
  description = "OPTIONAL: Name of an existing EC2 KeyPair to enable SSH access to the instances. Required only if an EC2ClientInstanceType is specified"
  type = string
}

variable "env" {
  description = "Environment tag, e.g. prod, nonprod."
  type = string
  default = "test"
}

variable "db_instance_type" {
  description = "Neptune DB instance type"
  type = string
  default = "db.r5.large"
}

variable "db_replica_identifier_suffix" {
  description = "OPTIONAL: The ID for the Neptune Replica to use. Empty means no read replica."
  type = string
}

variable "db_cluster_port" {
  description = "Enter the port of your Neptune cluster"
  type = string
  default = "8182"
}

variable "ec2_client_instance_type" {
  description = "OPTIONAL: EC2 client instance. Required only if EC2 client needs to setup. Please refer to https://aws.amazon.com/ec2/pricing/ for pricing."
  type = string
  default = "r5.2xlarge"
}

variable "neptune_query_timeout" {
  description = "Neptune Query Time out (in milliseconds)"
  type = string
  default = 20000
}

variable "neptune_enable_audit_log" {
  description = "Enable Audit Log. 0 means disable and 1 means enable."
  type = string
  default = 0
}

variable "iam_auth_enabled" {
  description = "Enable IAM Auth for Neptune."
  type = string
  default = "false"
}

variable "setup_gremlin_console" {
  description = "OPTIONAL: Setup Gremlin console on EC2 client. Used only if EC2ClientInstanceType is specified."
  type = string
  default = "false"
}

variable "setup_rdf4_j_console" {
  description = "OPTIONAL: Setup RDF4J console on EC2 client. Used only if EC2ClientInstanceType is specified."
  type = string
  default = "false"
}

variable "attach_bulkload_iam_role_to_neptune_cluster" {
  description = "Attach Bulkload IAM role to cluster"
  type = string
  default = "true"
}

variable "notebook_instance_type" {
  description = "SageMaker Notebook instance type. Please refer https://aws.amazon.com/sagemaker/pricing/ for uptodate allowed instance type in aws region and https://aws.amazon.com/neptune/pricing/ for pricing."
  type = string
  default = "none"
}

variable "neptune_sagemaker_notebook_startup_script" {
  description = "OPTIONAL: Startup script additions for the notebook instance."
  type = string
}

resource "aws_cloudformation_stack" "neptune_stack" {
  template_url = join("", ["https://s3.amazonaws.com/aws-neptune-customer-samples/v2/cloudformation-templates/neptune-base-stack.json"])
  timeout_in_minutes = "60"
  parameters = {
    Env = var.env
    DBReplicaIdentifierSuffix = var.db_replica_identifier_suffix
    DBClusterPort = var.db_cluster_port
    DbInstanceType = var.db_instance_type
    NeptuneQueryTimeout = var.neptune_query_timeout
    NeptuneEnableAuditLog = var.neptune_enable_audit_log
    IamAuthEnabled = var.iam_auth_enabled
    AttachBulkloadIAMRoleToNeptuneCluster = var.attach_bulkload_iam_role_to_neptune_cluster
  }
}

resource "aws_cloudformation_stack" "neptune_ec2_client" {
  count = locals.CreateEC2Instance ? 1 : 0
  template_url = join("", ["https://s3.amazonaws.com/aws-neptune-customer-samples/v2/cloudformation-templates/neptune-ec2-client.json"])
  timeout_in_minutes = "30"
  parameters = {
    Env = var.env
    EC2SSHKeyPairName = var.ec2_ssh_key_pair_name
    EC2ClientInstanceType = var.ec2_client_instance_type
    SetupGremlinConsole = var.setup_gremlin_console
    SetupRDF4JConsole = var.setup_rdf4_j_console
    VPC = aws_cloudformation_stack.neptune_stack.outputs.VPC
    Subnet = aws_cloudformation_stack.neptune_stack.outputs.PublicSubnet1
    NeptuneDBCluster = aws_cloudformation_stack.neptune_stack.outputs.DBClusterId
    NeptuneDBClusterEndpoint = aws_cloudformation_stack.neptune_stack.outputs.DBClusterEndpoint
    NeptuneDBClusterPort = aws_cloudformation_stack.neptune_stack.outputs.DBClusterPort
    NeptuneSG = aws_cloudformation_stack.neptune_stack.outputs.NeptuneSG
    NeptuneEC2InstanceProfile = aws_cloudformation_stack.neptune_stack.outputs.NeptuneEC2InstanceProfile
  }
}

resource "aws_cloudformation_stack" "neptune_sagemaker_notebook" {
  count = locals.CreateSagemakerNotebook ? 1 : 0
  template_url = join("", ["https://s3.amazonaws.com/aws-neptune-customer-samples/v2/cloudformation-templates/neptune-sagemaker-notebook-stack.json"])
  timeout_in_minutes = "30"
  parameters = {
    Env = var.env
    NotebookInstanceType = var.notebook_instance_type
    NeptuneClusterEndpoint = aws_cloudformation_stack.neptune_stack.outputs.DBClusterEndpoint
    NeptuneClusterPort = aws_cloudformation_stack.neptune_stack.outputs.DBClusterPort
    NeptuneClusterVpc = aws_cloudformation_stack.neptune_stack.outputs.VPC
    NeptuneClusterSubnetId = aws_cloudformation_stack.neptune_stack.outputs.PublicSubnet1
    NeptuneClientSecurityGroup = aws_cloudformation_stack.neptune_stack.outputs.NeptuneSG
    NeptuneLoadFromS3RoleArn = aws_cloudformation_stack.neptune_stack.outputs.NeptuneLoadFromS3IAMRoleArn
    StartupScript = var.neptune_sagemaker_notebook_startup_script
    DBClusterId = aws_cloudformation_stack.neptune_stack.outputs.DBClusterId
    NeptuneClusterResourceId = aws_cloudformation_stack.neptune_stack.outputs.DBClusterResourceId
    EnableIamAuthOnNeptune = var.iam_auth_enabled
  }
}
