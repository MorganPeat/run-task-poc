provider "random" {}

# HashiCorp internal provider that issues temporary credentials
# which the AWS provider uses
provider "doormat" {}

data "doormat_aws_credentials" "creds" {
  role_arn = var.aws_role_arn
}

provider "aws" {
  region     = "eu-west-2" # London
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

provider "tfe" {
  organization = var.tfe_organization
}
