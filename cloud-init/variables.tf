variable "fqdn" {
  description = "The Fully Qualified Domain Name of the Host to set"
  type        = string
  default     = null
}

variable "separate_home_volume" {
  description = "The device name of a separate volume to use for /home (e.g. 'xvdb')"
  type        = string
  default     = null
}

variable "additional_volumes" {
  description = "Additional volumes to prepare and mount (e.g. [{volume = \"xvdc\", mount_point = \"/backup\" }])"
  type = list(object({
    volume      = string,
    mount_point = string,
  }))
  default = []
}

variable "additional_parts" {
  description = "Additional cloud-init parts"
  type = list(object({
    content_type = string,
    filename     = string,
    content      = string
  }))
  default = []
}

variable "reboot" {
  description = "Whether to reboot after completing cloud-init"
  type        = bool
  default     = true
}
