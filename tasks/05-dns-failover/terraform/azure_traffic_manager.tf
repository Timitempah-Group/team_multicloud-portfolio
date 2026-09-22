# Priority routing (not Weighted) -- this is deliberately proving
# disaster-recovery failover behaviour, not load distribution across
# both clouds simultaneously.
resource "azurerm_traffic_manager_profile" "main" {
  name                = "tm-multicloud-portfolio"
  resource_group_name = "rg-multicloud-portfolio"

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "mc-portfolio-tm"
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "05-dns-failover"
  }
}

resource "azurerm_traffic_manager_external_endpoint" "aws_primary" {
  name       = "aws-primary"
  profile_id = azurerm_traffic_manager_profile.main.id
  target     = data.terraform_remote_state.task3.outputs.alb_dns_name
  priority   = 1
}

resource "azurerm_traffic_manager_external_endpoint" "azure_secondary" {
  name       = "azure-secondary"
  profile_id = azurerm_traffic_manager_profile.main.id
  target     = data.terraform_remote_state.task4.outputs.appgw_fqdn
  priority   = 2
}
