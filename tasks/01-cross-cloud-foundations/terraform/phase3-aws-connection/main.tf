# Generates a random, sufficiently complex pre-shared key instead of a
# hardcoded string. Azure's VPN PSK requirements: 8-128 chars, no leading "0".
resource "random_password" "vpn_psk" {
  length  = 32
  special = false # Azure PSK field has character restrictions; alphanumeric is safest
}

# Stores the generated key in Secrets Manager as the single source of truth.
# This does not change how the key reaches the VPN Connection resource below --
# Terraform still has to pass the raw value directly, since AWS's VPN Connection
# resource has no mechanism to pull a PSK by reference from Secrets Manager.
# What this buys us: one governed, audit-logged, access-controlled place to
# retrieve or rotate the key from later, instead of only Terraform state.
resource "aws_secretsmanager_secret" "vpn_psk" {
  name        = "multicloud-portfolio/vpn-psk"
  description = "Pre-shared key for the AWS-Azure Site-to-Site VPN tunnel (Task 1)"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

resource "aws_secretsmanager_secret_version" "vpn_psk" {
  secret_id     = aws_secretsmanager_secret.vpn_psk.id
  secret_string = random_password.vpn_psk.result
}

# AWS's record of the remote tunnel endpoint (Azure's public IP).
# bgp_asn is required by the resource schema even though BGP itself isn't
# used here -- 65000 is a standard private-use ASN placeholder for static routing.
resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65000
  ip_address = data.terraform_remote_state.phase1.outputs.azure_public_ip_address
  type       = "ipsec.1"

  tags = {
    Name    = "cgw-azure-multicloud"
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

# The actual IPsec VPN Connection -- AWS's half of the tunnel.
# static_routes_only = true because we're using static routing, not BGP.
# Both tunnels use the same generated key, read from the Secrets Manager
# secret version above, so there is exactly one canonical value in play.
resource "aws_vpn_connection" "azure" {
  customer_gateway_id = aws_customer_gateway.azure.id
  vpn_gateway_id      = data.terraform_remote_state.phase1.outputs.aws_vpn_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_preshared_key = aws_secretsmanager_secret_version.vpn_psk.secret_string
  tunnel2_preshared_key = aws_secretsmanager_secret_version.vpn_psk.secret_string

  tags = {
    Name    = "vpn-aws-to-azure"
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

# Tells AWS's private route table: traffic for Azure's address range (10.200.0.0/16)
# goes down this VPN connection.
resource "aws_vpn_connection_route" "to_azure" {
  vpn_connection_id      = aws_vpn_connection.azure.id
  destination_cidr_block = data.terraform_remote_state.phase1.outputs.azure_vnet_cidr
}
