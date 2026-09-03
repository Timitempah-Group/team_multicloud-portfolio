# Reads the actual PSK value out of Secrets Manager at apply time, using
# the ARN Phase 3 output -- this is how the same key reaches both AWS's
# and Azure's tunnel configuration without ever being retyped or duplicated
data "aws_secretsmanager_secret_version" "vpn_psk" {
  secret_id = data.terraform_remote_state.phase3.outputs.vpn_psk_secret_arn
}

# Azure's record of the remote (AWS) tunnel endpoint -- mirrors what
# aws_customer_gateway did on the AWS side in Phase 3.
# gateway_address points at AWS tunnel 1; address_space is the CIDR range
# that lives behind that endpoint (the AWS VPC), so Azure knows what
# traffic to route down this connection.
resource "azurerm_local_network_gateway" "aws" {
  name                = "lgw-aws-multicloud"
  location            = "uksouth"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  gateway_address     = data.terraform_remote_state.phase3.outputs.aws_tunnel1_address
  address_space       = [data.terraform_remote_state.phase1.outputs.aws_vpc_cidr]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

# The actual Connection resource -- Azure's half of the IPsec tunnel.
# type = "IPSec" (site-to-site, not ExpressRoute or VNet-to-VNet).
# shared_key must exactly match the PSK AWS's VPN Connection was configured
# with in Phase 3 -- read live from Secrets Manager above, not hardcoded,
# so there is only ever one canonical value to keep in sync.
resource "azurerm_virtual_network_gateway_connection" "to_aws" {
  name                       = "conn-azure-to-aws"
  location                   = "uksouth"
  resource_group_name        = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = data.terraform_remote_state.phase2.outputs.azure_vpn_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id
  shared_key                 = data.aws_secretsmanager_secret_version.vpn_psk.secret_string

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}


# ── Second tunnel for high availability ──────────────────────────────────
# AWS provisions two tunnel endpoints per VPN Connection for redundancy, but
# each requires its own Azure Local Network Gateway + Connection pair --
# Azure has no equivalent of "one Connection, two tunnels" the way AWS does.
# Without this second pair, AWS's own console flags the connection as
# "not highly available" -- if tunnel 1's endpoint has an outage, there is
# no automatic failover to tunnel 2 unless Azure is also configured to use it.
resource "azurerm_local_network_gateway" "aws_tunnel2" {
  name                = "lgw-aws-multicloud-tunnel2"
  location            = "uksouth"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  gateway_address     = data.terraform_remote_state.phase3.outputs.aws_tunnel2_address
  address_space       = [data.terraform_remote_state.phase1.outputs.aws_vpc_cidr]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

# Same shared key as the first connection -- AWS's aws_vpn_connection resource
# configured both tunnel1_preshared_key and tunnel2_preshared_key with the
# identical value from Secrets Manager, so both Azure connections use the
# same key read from the same secret.
resource "azurerm_virtual_network_gateway_connection" "to_aws_tunnel2" {
  name                       = "conn-azure-to-aws-tunnel2"
  location                   = "uksouth"
  resource_group_name        = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = data.terraform_remote_state.phase2.outputs.azure_vpn_gateway_id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_tunnel2.id
  shared_key                 = data.aws_secretsmanager_secret_version.vpn_psk.secret_string

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}
