# One shared password for both the RDS admin user and the Azure SQL admin
# login. Generated randomly rather than hardcoded, and stored in Secrets
# Manager as the single source of truth -- same pattern used for the VPN
# pre-shared key in Task 1. As with that key, the raw value still has to be
# passed directly to both the aws_db_instance and azurerm_mssql_server
# resources, since neither supports pulling a password by reference from
# Secrets Manager -- what this buys is one governed, auditable place to
# retrieve the value later, not elimination of the value from Terraform state.
resource "random_password" "db_admin" {
  length  = 20
  special = false # Avoids characters that MySQL/SQL Server connection strings can mishandle
}

resource "aws_secretsmanager_secret" "db_admin" {
  name        = "multicloud-portfolio/task02-db-admin-password"
  description = "Shared admin password for the source RDS instance and target Azure SQL Database (Task 2)"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

resource "aws_secretsmanager_secret_version" "db_admin" {
  secret_id     = aws_secretsmanager_secret.db_admin.id
  secret_string = random_password.db_admin.result
}
