# Azure's "folder" that groups every resource for this task together
resource "azurerm_resource_group" "main" {
  name     = "rg-multicloud-portfolio"
  location = var.azure_location
  tags = {
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# The Azure "building" itself — the private network everything Azure-side lives inside
resource "azurerm_virtual_network" "main" {
  name                = "vnet-multicloud-portfolio"
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# A specially-named "room" Azure requires to exist before the VPN Gateway
# can be built into it — the name "GatewaySubnet" is fixed, do not change it
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.200.0.0/27"]
}

# A normal "room" for whatever gets deployed here later (Task 4's workload)
resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.200.1.0/24"]
}

# Azure's "street address" — a fixed public IP that AWS will need to know
# in order to send traffic toward Azure's side of the tunnel
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-multicloud-vpn-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Required for AZ-SKU VPN Gateways -- must be zone-redundant
  tags = {
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}
