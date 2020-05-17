variable "location" {
  type        = string
  description = "The location where the resources should be created."
}

variable "cloudperf_name" {
  type        = string
  description = "The cloudperf instance name."
  default     = "cloudperf"
}

variable "instance_type" {
  type        = string
  description = "The cloudperf instance size."
}

variable "cloudperf_os_disk_size_gb" {
  type        = number
  description = "The Size of the Internal OS Disk in GB."
  default     = 30
}

variable "cloudperf_os_disk_caching" {
  type        = string
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite."
  default     = "ReadWrite"
}

variable "cloudperf_os_disk_storage_account_type" {
  type        = string
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "StandardSSD_LRS"
}

variable "ssh_user" {
  description = "The ssh user."
  default     = "quortex"
}