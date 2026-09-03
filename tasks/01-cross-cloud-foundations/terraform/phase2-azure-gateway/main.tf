# Looks up the static public IP created in Phase 1 by name and resource group,
# rather than hardcoding its resource ID — avoids any subscription-specific
# string construction and stays valid if the subscription ever changes
data "azurerm_public_ip" "vpn_gateway" {
  name                = data.terraform_remote_state.phase1.outputs.azure_public_ip_name
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
}

# The actual Azure VPN Gateway — a route-based, IPsec-capable gateway
# deployed into the reserved GatewaySubnet from Phase 1.
# VpnGw1 is the smallest paid SKU that supports route-based VPN — sufficient
# for portfolio-scale throughput, not intended for production traffic volumes.
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vgw-multicloud-portfolio"
  location            = "uksouth"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ" # AZ SKU required -- non-AZ VpnGw1-5 SKUs are deprecated for new gateways

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = data.azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.terraform_remote_state.phase1.outputs.azure_gateway_subnet_id
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}
