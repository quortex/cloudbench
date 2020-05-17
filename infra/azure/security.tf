
# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "cloudperf" {
  network_interface_id      = azurerm_network_interface.cloudperf.id
  network_security_group_id = azurerm_network_security_group.cloudperf.id
}

# Subnet <-> Network Security Group associations.
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.cloudperf.id
  network_security_group_id = azurerm_network_security_group.cloudperf.id
}

# Manages a network security group that contains a list of network security rules asssociated to private Appcloudperf.
resource "azurerm_network_security_group" "cloudperf" {
  name                = "mySecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.cloudperf.name
}

# Allow incoming traffic from a source IP or IP range and the destination as either the entire Application cloudperf subnet, or to the specific configured private front-end IP. The NSG doesn't work on a public IP.
resource "azurerm_network_security_rule" "allow_whitelisted_ips" {

  name                        = "AllowWhitelistedIPs"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.cloudperf.name
  network_security_group_name = azurerm_network_security_group.cloudperf.name
}


