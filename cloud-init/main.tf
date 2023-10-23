data "cloudinit_config" "computed" {
  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = local.parts
    content {
      content_type = part.value["content_type"]
      filename     = part.value["filename"]
      content      = part.value["content"]
    }
  }
}