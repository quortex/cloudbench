resource "azurerm_resource_group" "cloudperf" {
  name     = "cloudperf-resources"
  location = var.location
}

resource "azurerm_linux_virtual_machine" "cloudperf" {
  name                  = var.cloudperf_name
  location              = var.location
  resource_group_name   = azurerm_resource_group.cloudperf.name
  network_interface_ids = [azurerm_network_interface.cloudperf.id]
  size                  = var.instance_type

  os_disk {
    disk_size_gb         = var.cloudperf_os_disk_size_gb
    caching              = var.cloudperf_os_disk_caching
    storage_account_type = var.cloudperf_os_disk_storage_account_type
  }

  # source_image_id = "OpenLogic:CentOS:7.5:latest"
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  admin_username                  = var.ssh_user
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file("~/.ssh/id_rsa.pub")
  }
}
