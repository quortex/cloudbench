resource "azurerm_virtual_network" "cloudperf" {
  name                = "cloudperf-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.cloudperf.name
}

# Create subnet
resource "azurerm_subnet" "cloudperf" {
  name                 = "cloudperf-subnet"
  resource_group_name  = azurerm_resource_group.cloudperf.name
  virtual_network_name = azurerm_virtual_network.cloudperf.name
  address_prefix       = "10.0.2.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "cloudperf" {
  name                = "myPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.cloudperf.name
  allocation_method   = "Dynamic"
}


# Create network interface
resource "azurerm_network_interface" "cloudperf" {
  name                = "myNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.cloudperf.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.cloudperf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloudperf.id
  }
}
