resource "aws_db_subnet_group" "main" {
  name = "multicloud-portfolio-db-subnets"
  # Uses both public subnets (across two AZs) rather than private ones --
  # RDS requires the subnet group to span two AZs, and this instance must
  # remain internet-reachable (publicly_accessible = true) for local seeding
  # and DMS access, which private subnets do not support without a NAT Gateway.
  subnet_ids = [
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_id,
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_b_id
  ]
}

# Allows MySQL (3306) from within the VPC (for DMS later) and from the
# local machine's IP (temporary, for seeding data directly)
resource "aws_security_group" "rds" {
  name        = "multicloud-portfolio-rds-sg"
  description = "Allows MySQL access from the VPC and temporarily from a local IP for seeding"
  vpc_id      = data.terraform_remote_state.phase1.outputs.aws_vpc_id

  ingress {
    description = "MySQL from within the VPC and from local machine for seeding"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.phase1.outputs.aws_vpc_cidr, var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

# The source database -- a small MySQL instance standing in for a real
# production database. publicly_accessible = true is required temporarily
# so both the local machine (seeding) and the DMS replication instance
# (Azure has no VPN dependency for this task) can reach it.
# A custom parameter group enabling binary logging in ROW format --
# required by DMS for CDC (ongoing change capture) against a MySQL source.
# RDS MySQL does not use ROW-format binlogging by default.
resource "aws_db_parameter_group" "mysql_cdc" {
  name   = "multicloud-portfolio-mysql-cdc"
  family = "mysql8.0"

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}

resource "aws_db_instance" "source" {
  identifier             = "multicloud-portfolio-source"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "portfolio"
  username               = "admin"
  password               = random_password.db_admin.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.mysql_cdc.name
  backup_retention_period = 1 # Required for DMS CDC -- binlog retention depends on backups being enabled

  tags = {
    Project = "multicloud-portfolio"
    Task    = "02-cross-cloud-data-migration"
  }
}
