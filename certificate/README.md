# Certificate Terraform module

Terraform module which creates a Certificate and Keys. You may create either a:
1. Root CA
2. Subordinate CA
3. Self-signed Certificate
4. CA signed Certificate

## Usage

### Example 1 - Root CA

This is an example of a Root CA.

```hcl
module "certificate_authority" {
  source = "./certificate"

  id = "project-omega-private-root"

  is_ca_certificate = true

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
module "subordinate_certificate_authority" {
  source = "./certificate"

  id = "project-omega-private-intermediate"

  is_ca_certificate = true

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

  ca = {
    private_key_pem = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-root-ca.private.key.pem")
    certificate_pem = file("../../../ctd-omega-infrastructure-certificates/exported/project-omega-private-root-ca.crt.pem")
  }
}
```

### Example 3 - Self-signed Certificate

This is an example of a self-signed certificate.

```hcl
module "certificate_1" {
  source = "./certificate"

  id = "certificate-1"

  is_ca_certificate = false

  subject = {
    common_name = "certificate-1.cert.omg.catalogue.nationalarchives.gov.uk"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }

  dns_names = [
    "certificate-1.cert.omg.catalogue.nationalarchives.gov.uk"
  ]

  expiry_days = 365  # 1 year
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"
}
```

### Example 4 - CA Signed Certificate

This is an example of a CA signed certificate.

```hcl
module "certificate_2" {
  source = "./certificate"

  id = "certificate-2"

  is_ca_certificate = false

  subject = {
    common_name = "certificate-2.cert.omg.catalogue.nationalarchives.gov.uk"
    organizational_unit = "The Cataloguing, Taxonomy, and Data Team"
    organization = "The National Archives"
    locality = "Kew"
    province = "London"
    country = "GB"
    postal_code = "TW9 4DU"

    serial_number = "0x1"
  }

  dns_names = [
    "certificate-2.cert.omg.catalogue.nationalarchives.gov.uk"
  ]

  expiry_days = 365  # 1 year
  export_path = "../../../ctd-omega-infrastructure-certificates/exported"

  ca = {
    private_key_pem = module.certificate_authority.private_key_pem
    certificate_pem = module.certificate_authority.certificate_pem
  }
}
```
