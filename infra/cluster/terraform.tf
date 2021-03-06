terraform {
  required_version = ">= 0.13"

  required_providers {
    aws      = {
      source  = "hashicorp/aws"
      version = "~> 3.22"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
    null     = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {}
}
