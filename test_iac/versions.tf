terraform {

  required_version = "~> 1.3.0" # Matches the TFE workspace - must be changed in sync

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}