# Terraform configuration.
terraform {
  required_version = ">= 0.12"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
