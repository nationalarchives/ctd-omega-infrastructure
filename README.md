# Project Omega - Infrastructure and Configuration as Code

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

Terraform is responsible for the setting up the infrastruture, and uses cloud-init as a hook to install and execute Puppet. Puppet is responsible for all software configuration.
