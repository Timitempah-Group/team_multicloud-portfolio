output "azure_local_network_gateway_id" {
  value = azurerm_local_network_gateway.aws.id
}

output "azure_connection_id" {
  value = azurerm_virtual_network_gateway_connection.to_aws.id
}

output "azure_connection_status" {
  value = azurerm_virtual_network_gateway_connection.to_aws.connection_protocol
}

output "azure_local_network_gateway_tunnel2_id" {
  value = azurerm_local_network_gateway.aws_tunnel2.id
}

output "azure_connection_tunnel2_id" {
  value = azurerm_virtual_network_gateway_connection.to_aws_tunnel2.id
}
