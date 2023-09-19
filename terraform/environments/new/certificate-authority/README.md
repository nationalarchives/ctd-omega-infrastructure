# Certificate Authority Terraform module

Terraform module which creates a Certificate Authority certificate and keys. You may create either a Root CA or a Subordinate CA.

## Usage

### Example 1 - Root CA

This is an example of a Root CA.

```hcl
module "certificate_authority" {
  source = "./certificate-authority"

  id = "project-omega-private-root"
  subject = {
    common_name = "root-ca.cert.omg.catalogue.nationalarchives.gov.uk"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }
  expiry_days = 10 * 365  # 10 years
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"
}
```

### Example 2 - Subordinate CA

This is an example of a Subordinate CA that is signed by the Root CA.

```hcl
module "certificate_authority" {
  source = "./certificate-authority"

  id = "project-omega-private-intermediate"
  subject = {
    common_name = "int-ca.cert.omg.catalogue.nationalarchives.gov.uk"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x2"
  }
  expiry_days = 10 * 365  # 5 years
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"

  root-ca {
    private_key_pem = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-root-ca.private.key.pem")
    certificate_pem = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-root-ca.crt.pem")
  }
}
```
