# terraform and providers required versions
terraform {
  required_version = "~> 0.12.6"

  required_providers {
    google = "~> 3.19"
    local  = "~> 1.4"
  }
}
