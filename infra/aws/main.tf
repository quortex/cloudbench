# aws provider configuration
# versions constraints defined in versions.tf
provider "aws" {
  region = var.region
  profile = var.aws_profile
}
