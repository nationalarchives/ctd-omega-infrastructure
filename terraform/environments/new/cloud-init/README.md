# cloud-init Terraform module

Terraform module which assists with setting up cloud-init data for EC2 instances.

## Usage

### Example 1 - Use cloud-init to set a hostname

```hcl
module "my_host_1_cloud_init" {
  source = "./cloud-init"

  fqdn = "my-host-1.my.domain.tld"
}

resource "aws_instance" "my_host_1" {

  user_data                   = module.my_host_1_cloud_init.rendered

  ...
```

### Example 2 - Use cloud-init to specify a separate Home volume

```hcl
module "my_host_1_cloud_init" {
  source = "./cloud-init"

  separate_home_volume = "xvdb"
}

resource "aws_instance" "my_host_1" {

  user_data                   = module.my_host_1_cloud_init.rendered

  ...
```

### Example 3 - Use cloud-init to mount additional volumes

```hcl
module "my_host_1_cloud_init" {
  source = "./cloud-init"

  additional_volumes = [
    {
      volume = "xvdb",
      mount_point = "/backup"
    },
    {
      volume = "xvdc",
      mount_point = "/extra-storage"
    }
  ]
}

resource "aws_instance" "my_host_1" {

  user_data                   = module.my_host_1_cloud_init.rendered

  ...
```

## Inputs

| Name | Description |
| ---- | ----------- |
| fqdn | Optional. The Fully Qualified Domain Name of the Host to set |
| separate_home_volume | Optional. If a separate volume is to be used for the '/home' folder then this should be set to the volume's device name (e.g. 'xvdb') |
| additional_volumes | Optional. Additional volumes to prepare and mount (e.g. [{volume = "xvdc", mount_point = "/backup" }]) |
| reboot | Whether to reboot after completing cloud-init. Default: true |

## Outputs

| Name | Description |
| ---- | ----------- |
| rendered | The rendered cloud-init config |
