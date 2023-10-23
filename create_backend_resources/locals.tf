locals {
  tags_common = {
    "EnvironmentName" = "${var.tags_environment_name}"
    "EnvironmentType" = "${var.tags_environment_type}"
    "Project"         = "${var.tags_project}"
    "ManagedBy"       = "terraform"
    "ServiceOwner"    = "${var.tags_owner}"
    "ServiceName"     = "${var.tags_project} ${var.tags_environment_type}"
    "CostCode"        = "n/a"
  }
}
