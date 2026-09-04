# AWS DMS requires this exact-named role to exist before it can create any
# VPC-related resources (like the subnet group below). Normally the DMS
# Console creates this automatically the first time someone uses the
# service through the UI -- since this portfolio goes straight to
# Terraform, it's created explicitly here instead, making the setup fully
# reproducible without depending on a prior manual console interaction.
resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "dms.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# DMS needs its own subnet group, same two-AZ requirement as RDS.
# Uses the public subnets since the replication instance needs internet
# access to reach Azure SQL's public endpoint.
resource "aws_dms_replication_subnet_group" "main" {
  depends_on                           = [aws_iam_role_policy_attachment.dms_vpc_role]
  replication_subnet_group_id          = "multicloud-portfolio-dms"
  replication_subnet_group_description = "DMS subnet group for cross-cloud migration"
  subnet_ids = [
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_id,
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_b_id
  ]
}

# The replication instance -- the managed server that actually performs
# the migration. Reuses the RDS security group since it already permits
# what's needed (outbound to anywhere, inbound MySQL from the VPC).
resource "aws_dms_replication_instance" "main" {
  replication_instance_id     = "multicloud-portfolio-dms"
  replication_instance_class  = "dms.t3.small" # dms.t3.micro is not a valid DMS class -- confirmed via describe-orderable-replication-instances
  allocated_storage           = 20
  publicly_accessible         = true
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  vpc_security_group_ids      = [aws_security_group.rds.id]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# Tells DMS how to connect to the source (the RDS MySQL instance)
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "multicloud-portfolio-source"
  endpoint_type = "source"
  engine_name   = "mysql"
  server_name   = aws_db_instance.source.address
  port          = 3306
  username      = "admin"
  password      = random_password.db_admin.result
  database_name = "portfolio"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# Tells DMS how to connect to the target (Azure SQL Database)
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "multicloud-portfolio-target"
  endpoint_type = "target"
  engine_name   = "sqlserver"
  server_name   = azurerm_mssql_server.main.fully_qualified_domain_name
  port          = 1433
  username      = "sqladmin"
  password      = random_password.db_admin.result
  database_name = "portfolio"

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# The actual migration task: full copy, then keep replicating ongoing
# changes (CDC) until manually stopped ahead of cutover. table_mappings
# scopes this to just the customers table -- the only table in this
# proof-of-migration database.
resource "aws_dms_replication_task" "main" {
  replication_task_id      = "multicloud-portfolio-migration"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  migration_type           = "full-load-and-cdc"

  table_mappings = jsonencode({
    rules = [{
      rule-type      = "selection"
      rule-id        = "1"
      rule-name      = "1"
      object-locator = { schema-name = "portfolio", table-name = "customers" }
      rule-action    = "include"
    }]
  })

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}
