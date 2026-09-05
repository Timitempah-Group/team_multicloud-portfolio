resource "azurerm_public_ip" "appgw" {
  name                = "pip-multicloud-task4-appgw"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "04-azure-workload"
  }
}

resource "azurerm_application_gateway" "main" {
  name                = "appgw-multicloud-task4"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = data.terraform_remote_state.phase1.outputs.azure_appgw_subnet_id
  }

  # Explicit modern SSL policy -- the provider's implicit default policy
  # (AppGwSslPolicy20150501) uses a deprecated TLS version that Azure now
  # rejects at creation time, even when no HTTPS listener is configured.
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend pool points at the App Service's default hostname (FQDN) --
  # Application Gateway reaches it over the public endpoint, not via
  # private VNet integration, keeping this task's networking simple.
  backend_address_pool {
    name  = "backend-pool"
    fqdns = [azurerm_linux_web_app.main.default_hostname]
  }

  # host_name must match the App Service's hostname exactly -- App Service
  # validates the Host header and rejects requests where it doesn't match,
  # which is why this can't be left as the Application Gateway's own address.
  backend_http_settings {
    name                                = "backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "04-azure-workload"
  }
}
