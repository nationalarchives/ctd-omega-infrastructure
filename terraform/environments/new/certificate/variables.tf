variable "id" {
  description = "The id of the certificate, e.g. puppet-server-1"
  type        = string
}

variable "is_ca_certificate" {
  description = "Is the generated certificate representing a Certificate Authority (CA)"
  type = bool
  default = false
}

variable "subject" {
  description = "Subject of the certificate"
  type        = map(any)
}

variable "dns_names" {
  description = "DNS Names for Subject Alternative Name"
  type = list(string)
  default = []
}

variable "expiry_days" {
  description = "The number of days after which the certificate expires"
  type        = number
  default     = 30
}

variable "early_renewal_hours" {
    description = "The resource will consider the certificate to have expired the given number of hours before its actual expiry time. This can be useful to deploy an updated certificate in advance of the expiration of the current certificate. However, the old certificate remains valid until its true expiration time, since this resource does not (and cannot) support certificate revocation. Also, this advance update can only be performed should the Terraform configuration be applied during the early renewal period."
    type        = number
    default     = 48
}

variable "export_path" {
  description = "The directory path to export the keys and certificate to"
  type        = string
  default     = null
}

variable "ca" {
  description = "The CA to use for signing this certificate"
  type        = map(string)
  default     = null
}
