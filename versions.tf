terraform {

  required_version = "~> 1.3.0" # Matches the TFE workspace - must be changed in sync

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0"
    }
    tfe = {
      version = "~> 0.42.0"
    }
  }
}