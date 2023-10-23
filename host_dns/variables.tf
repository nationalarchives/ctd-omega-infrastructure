variable "fqdn" {
  description = "The Fully Qualified Domain Name of the Host to create DNS entries for"
  type        = string
}

variable "zone_id" {
  description = "The id of the Route53 DNS zone in which to place the DNS records"
  type        = string
}

variable "ipv4" {
  type = object({
    addresses       = list(string),
    reverse_zone_id = optional(string)
  })
}

variable "ipv6" {
  type = object({
    addresses       = list(string),
    reverse_zone_id = optional(string)
  })
  default = null
}
