output "cloudperf_internal_ip" {
  value = azurerm_linux_virtual_machine.cloudperf.private_ip_address
}

output "cloudperf_external_ip" {
  value = azurerm_linux_virtual_machine.cloudperf.public_ip_address
}

output "ssh_user" {
  value = var.ssh_user
}
