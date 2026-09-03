# These values get printed after "terraform apply" and get read by later
# phases and tasks that depend on what got built here.
output "aws_vpc_id" { value = aws_vpc.main.id }
output "aws_vpc_cidr" { value = var.aws_vpc_cidr }
output "aws_public_subnet_id" { value = aws_subnet.public.id }
output "aws_private_subnet_id" { value = aws_subnet.private.id }
output "aws_private_route_table_id" { value = aws_route_table.private.id }
output "aws_vpn_gateway_id" { value = aws_vpn_gateway.main.id }
output "azure_resource_group_name" { value = azurerm_resource_group.main.name }
output "azure_vnet_name" { value = azurerm_virtual_network.main.name }
output "azure_vnet_cidr" { value = var.azure_vnet_cidr }
output "azure_gateway_subnet_id" { value = azurerm_subnet.gateway.id }
output "azure_workload_subnet_id" { value = azurerm_subnet.workload.id }
output "azure_public_ip_name" { value = azurerm_public_ip.vpn_gateway.name }
output "azure_public_ip_address" { value = azurerm_public_ip.vpn_gateway.ip_address }
