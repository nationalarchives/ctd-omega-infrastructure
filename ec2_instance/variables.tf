variable "fqdn" {
  description = "The Fully Qualified Domain Name of the Host to set"
  type        = string
}

variable "ami" {
  description = "AMI to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use for the instance"
  type        = string
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
}

variable "iam_instance_profile" {
  description = "The IAM instance profile to add, if omitted an IAM instance profile will be generated"
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "Additional IAM policies to add to the IAM instance profile. Only used if 'iam_instance_profile' is omitted"
  type        = list(string)
  default     = []
}

variable "user_data_replace_on_change" {
  description = "User data to provide when launching the instance"
  type        = bool
  default     = false
}

variable "puppet" {
  description = "Settings for controlling if and how Puppet Server and/or Puppet Agent is installed on this instance"
  type = object({
    version     = optional(number, 8)
    server_fqdn = optional(string) # only needed when configuring as a Puppet Agent, Puppet Server uses `var.fqdn` by default.
    server = optional(object({
      control_repo_url = string,
      environment      = optional(string, "production")
      ca = optional(object({
        public_key_filename  = string,
        private_key_filename = string,
        subject = optional(object({
          common_name         = optional(string),
          organizational_unit = optional(string),
          organization        = optional(string),
          street_address      = optional(list(string), []),
          locality            = optional(string),
          province            = optional(string),
          country             = optional(string),
          postal_code         = optional(string),
          serial_number       = optional(string)
        }))
      }), null)
      agents = optional(list(object({
        fqdn                 = string,
        certificate_filename = optional(string),
        public_key_filename  = optional(string),
        private_key_filename = optional(string)
      })), [])
    })),
    certificates = object({
      s3_bucket_name                       = string,
      s3_bucket_certificates_public_policy = string,
      s3_bucket_ca_public_policy           = string,
      s3_bucket_ca_private_policy          = string,
      ca_certificate_filename              = optional(string),
      ca_certificate_pem                   = optional(string),
      ca_private_key_pem                   = optional(string),
      self = optional(object({
        certificate_filename = string,
        public_key_filename  = string,
        private_key_filename = string,
        subject = optional(object({
          common_name         = optional(string),
          organizational_unit = optional(string),
          organization        = optional(string),
          street_address      = optional(list(string), []),
          locality            = optional(string),
          province            = optional(string),
          country             = optional(string),
          postal_code         = optional(string),
          serial_number       = optional(string)
        }))
      }))
    }),
  })
  default = null
}

variable "root_block_device" {
  description = "Settings for the root block device. Optional keys are: 'delete_on_termination', 'encrypted', 'volume_type', 'iops', 'throughput', and 'volume_size'"
  type = object({
    delete_on_termination = optional(bool, false),
    encrypted             = optional(bool, false),
    volume_type           = optional(string, "gp3"),
    iops                  = optional(number, 3000),
    throughput            = optional(number, 125), # MiB/s
    volume_size           = number,
    tags                  = optional(map(string))
  })
}

variable "home_block_device" {
  description = "Settings for the home block device. Optional keys are: 'device_name', 'delete_on_termination', 'encrypted', 'volume_type', 'iops', 'throughput', and 'volume_size'"
  type = object({
    device_name           = string,
    delete_on_termination = optional(bool, false),
    encrypted             = optional(bool, false),
    volume_type           = optional(string, "gp3"),
    iops                  = optional(number, 3000),
    throughput            = optional(number, 125), # MiB/s
    volume_size           = number,
    tags                  = optional(map(string))
  })
  default = null
}

variable "secondary_block_devices" {
  description = "Settings for secondary block devices. Optional keys are: 'device_name', 'mount_point', 'delete_on_termination', 'encrypted', 'volume_type', 'iops', 'throughput', and 'volume_size'"
  type = list(object({
    device_name           = string,
    mount_point           = string,
    delete_on_termination = optional(bool, false),
    encrypted             = optional(bool, false),
    volume_type           = optional(string, "gp3"),
    iops                  = optional(number, 3000),
    throughput            = optional(number, 125), # MiB/s
    volume_size           = number,
    tags                  = optional(map(string))
  }))
  default = []
}

variable network_interfaces {
  description = "List of network interfaces to create and their network details"
  type = list(object({
    subnet_id = string,
    private_ips = list(string),
    security_groups = optional(list(string), null)
  }))
}

variable "dns" {
  description = "DNS Zones, if present DNS records will be generated for the zones"
  type = object({
    zone_id              = string,
    reverse_ipv4_zone_id = optional(string),
    reverse_ipv6_zone_id = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Additional tags for the instance"
  type        = map(string)
  default     = {}
}
