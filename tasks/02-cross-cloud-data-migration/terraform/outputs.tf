output "rds_endpoint" {
  value = aws_db_instance.source.address
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "azure_sql_server_name" {
  value = azurerm_mssql_server.main.name
}

output "azure_sql_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "db_admin_secret_arn" {
  value = aws_secretsmanager_secret.db_admin.arn
}
