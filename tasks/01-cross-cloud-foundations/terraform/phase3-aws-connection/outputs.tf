output "aws_customer_gateway_id" {
  value = aws_customer_gateway.azure.id
}

output "aws_vpn_connection_id" {
  value = aws_vpn_connection.azure.id
}

output "aws_tunnel1_address" {
  value = aws_vpn_connection.azure.tunnel1_address
}

output "aws_tunnel2_address" {
  value = aws_vpn_connection.azure.tunnel2_address
}

# Phase 4 (Azure's side) reads the PSK from here rather than from a
# hardcoded value or from this state file directly
output "vpn_psk_secret_arn" {
  value = aws_secretsmanager_secret.vpn_psk.arn
}
