# terraform and providers required versions
terraform {
#  required_version = "~> 0.12.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}