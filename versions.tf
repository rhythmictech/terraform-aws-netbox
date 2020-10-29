terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.65"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 1.2"
    }

    template = {
      source  = "hashicorp/template"
      version = ">= 2.1"
    }
  }
}
