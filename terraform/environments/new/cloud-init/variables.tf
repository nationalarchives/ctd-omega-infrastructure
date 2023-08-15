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

variable "reboot" {
    description = "Whether to reboot after completing cloud-init"
    type = bool
    default = true
}
