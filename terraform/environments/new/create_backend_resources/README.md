# Terraform Remote State Config

  When creating a new environment please execute the following commands in this "create_backend_resources" directory so that Terraform first creates the required resources for a backend, ie the S3 bucket and dynamodb table locking mechanism.
  Once this is complete then you can move into the parent directory and create the actual backend and all other resources for the environment.

  cd create_backend_resources ;
  terraform init ;
  terraform apply ;
  cd .. ;
  terraform init ;


  Now you can apply the terraform config in the parent directory to create the backend and the environment with the usual terraform commands.

  terraform plan ;
  terraform apply ;
