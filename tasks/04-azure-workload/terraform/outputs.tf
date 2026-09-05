output "app_service_hostname" {
  value = azurerm_linux_web_app.main.default_hostname
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}
