# These feed Phase 4 (Azure Local Network Gateway + Connection)
output "azure_vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.main.id
}

output "azure_vpn_gateway_name" {
  value = azurerm_virtual_network_gateway.main.name
}
