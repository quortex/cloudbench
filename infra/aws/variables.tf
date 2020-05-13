variable "region" {
  description = "The region in which to deploy resources."
}

variable "availability_zone" {
  description = "The availability zone in which to deploy resources."
}

variable "instance_type" {
  description = "The EC2 instance type for cloudperf."
}

variable "ssh_user" {
  description = "The ssh user."
  default     = "admin"
}

variable "ssh_pub_key_file" {
  description = "The ssh public key file."
  default     = "~/.ssh/id_rsa.pub"
}
