# The target -- a logical Azure SQL Server (not a VM) hosting the migrated database.
resource "azurerm_mssql_server" "main" {
  name                         = "sql-multicloud-portfolio"
  resource_group_name         = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location                     = "uksouth"
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.db_admin.result

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# Basic tier -- lowest cost, sufficient for a small proof-of-migration dataset
resource "azurerm_mssql_database" "main" {
  name      = "portfolio"
  server_id = azurerm_mssql_server.main.id
  sku_name  = "Basic"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# Temporary rule allowing the local machine to connect directly for seeding/verification
resource "azurerm_mssql_firewall_rule" "my_ip" {
  name             = "allow-my-ip-seed"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = split("/", var.my_ip)[0]
  end_ip_address   = split("/", var.my_ip)[0]
}
