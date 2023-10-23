# Project Omega - Infrastructure and Configuration as Code

[![CI](https://github.com/nationalarchives/ctd-omega-infrastructure/actions/workflows/ci.yml/badge.svg)](https://github.com/nationalarchives/ctd-omega-infrastructure/actions/workflows/ci.yml)

This repository contains Infrastructure as Code in the form of a set of [Terraform](https://www.terraform.io/) scripts in the https://github.com/nationalarchives/tna-cat/tree/ctd-omega-infrastructure/terraform folder.

## Approach
The Terraform scripts are applied to the AWS VPC for Project Omega using the `terraform apply` CLI from a remote host with general internet access. Terraform uses the AWS SDK API to communicate with AWS and provision the AWS infrastructure within the VPC account for Project Omega.

Terraform configures each EC2 instance with a number of [cloud-init](https://cloud-init.io/) scripts. These cloud-init scripts take the following steps:
1. Execute a Bash script to update to the latest Yum packages.
2. Execute a Bash script to install either Puppet Server or Puppet agent via Yum.
3. Reboots the system after cloud-init completes.

Terraform is responsible for the setting up the infrastruture, and uses cloud-init as a hook to install Puppet. The cloud-init scripts are deployed via AWS EC2's User Data. After that point, Puppet is responsible for all software configuration. The Puppet Scripts for Project Omega are located in the Puppet Control repository here: https://github.com/nationalarchives/ctd-omega-puppet.

## Terraform
Terraform state is stored in an S3 bucket with locking via DynamoDB, see the `backend.rf` file for details.

This repository uses Git sub-modules to store generated Certificates for use in AWS.

To correctly clone this repository you need to run something like:

```bash
$ git clone https://github.com/nationalarchives/ctd-omega-infrastructure.git
$ cd ctd-omega-infrastructure

$ git submodule init
$ git submodule update
```

or you can use the shorter version:
```bash
$ git clone --recurse-submodules https://github.com/nationalarchives/ctd-omega-infrastructure.git
```

### To Initialise the Terraform S3 Backend
```bash
$ cd ctd-omega-infrastructure/create_backend_resources
$ terraform init
```
This next terraform *apply* command will create the resources required for an s3 remote state backend. These Terraform commands only need to be executed once, just before creating a new environment. Terraform is idempotent so nothing should break if you decide to run terraform several times in this current directory.
```bash
$ terraform apply
```

### Getting Started with Terraform
This next terraform *init* command will initialise Terraform for the actual Project Omega AWS Environment.
```bash
$ cd ctd-omega-infrastructure
$ terraform init
```

### Updating the AWS Environment with Terraform
To update the AWS Environment using Terraform, simply modify and/or add to the `.tf` files in this repository and then run terraform's *apply* command.
```bash
$ cd ctd-omega-infrastructure
$ terraform apply
```