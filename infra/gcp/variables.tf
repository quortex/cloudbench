variable "project_id" {
  description = "The project in which to create resources."
}

variable "region" {
  description = "The default region in which to create resources."
  default = "europe-west1"
}

variable "zone" {
  description = "The compute engine VM zone."
  default = "europe-west1-c"
}

variable "instance_name" {
  description = "The cloudperf name."
  default = "cloudperf-unnamed"
}

variable "instance_type" {
  description = "The Compute engine VM machine type."
}

variable "ssh_user" {
  description = "The ssh user."
  default     = "quortex"
}

variable "min_cpu_platform" {
  description = "The minimal CPU to use"
  default     = ""
}

variable "ssh_pub_key_file" {
  description = "The ssh public key file."
  default     = "~/.ssh/id_rsa.pub"
}
