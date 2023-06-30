# Project Omega - Infrastructure and Configuration as Code

[![CI](https://github.com/nationalarchives/ctd-omega-infrastructure/actions/workflows/ci.yml/badge.svg)](https://github.com/nationalarchives/ctd-omega-infrastructure/actions/workflows/ci.yml)

This repository contains:

1. Infrastructure as Code in the form of a set of [Terraform](https://www.terraform.io/) scripts in the https://github.com/nationalarchives/tna-cat/tree/ctd-omega-infrastructure/terraform folder.

2. Configuration as Code in the form of a set of [Puppet](https://www.puppet.com/) agent scripts in the https://github.com/nationalarchives/ctd-omega-infrastructure/tree/main/puppet folder.

## Approach
The Terraform scripts are applied to the AWS VPC for Project Omega using the `terraform apply` CLI from a remote host with general internet access. Terraform uses the AWS SDK API to communicate with AWS and provision the AWS infrastructure within the VPC account for Project Omega.

Terraform configures each EC2 instance with a number of [cloud-init](https://cloud-init.io/) scripts. These cloud-init scripts take the following steps:
1. Execute a Bash script to update to the latest Yum packages
2. Execute a Bash script to install Puppet agent via Yum
3. Deploy a set of Puppet agent .pp script files to a known location on the machine
4. Execute a Bash script which calls the Puppet agent to execute the .pp script files
5. Reboots the system after cloud-init completes

Terraform is responsible for the setting up the infrastruture, and uses cloud-init as a hook to install and execute Puppet. Puppet is responsible for all software configuration.

## Terraform
This repository used a Git sub-module to store Terraform state in a separate private repository. To correctly clone this repository for use with Terraform (assuming you have permissions to access the Terraform state repository), you need to run something like:

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

## New approach for Terraform code in the development branch
```bash
$ git checkout development
$ cd terraform
$ cd environments/development/create_backend_resources
$ terraform init
```
This next terraform apply command will create the resources required for an s3 remote state backend. These Terraform commands only need to be executed once, just before creating a new environment. Terraform is idempotent so nothing should break if you decide to run terraform several times in this current directory.
```bash
$ terraform apply
$ cd ..
```
This next terraform init command will create the actual 'backend' resource using the s3 bucket and the dynamodb table defined in the 'create_backend_resources' directory.
```bash
$ terraform init
```
