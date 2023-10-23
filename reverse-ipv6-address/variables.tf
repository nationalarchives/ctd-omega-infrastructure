variable "ipv6_address" {
  description = "The IPv6 Address that should be reversed"
  type        = string
  default     = null
}

variable "reverse_dns_zone_name_class_count" {
  description = "The number of clases that should be included in the reversed IPv6 Address (counting from right-to-left in the reversed address)"
  type        = number
  default     = 32
}
