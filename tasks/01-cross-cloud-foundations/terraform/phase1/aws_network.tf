# The AWS "building" itself — the private network everything AWS-side lives inside
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "multicloud-portfolio-vpc"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# A "room" inside the building that can reach the internet directly
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name    = "multicloud-portfolio-public-a"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# A "room" that has no direct internet access — this is where the future
# database and internal workloads will sit, safer from public exposure
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name    = "multicloud-portfolio-private-a"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# The "front door" of the building — lets the public subnet reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "multicloud-portfolio-igw"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# The signpost for the public subnet: "anything not local, send out the front door"
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name    = "multicloud-portfolio-public-rt"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# The signpost for the private subnet — empty for now, the VPN route
# gets added to this automatically once the tunnel exists (see propagation below)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "multicloud-portfolio-private-rt"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# Connects the public subnet to its signpost
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# A second public subnet in a different AZ. Needed because RDS requires a
# DB Subnet Group to span at least two AZs, and this task's RDS instance
# must remain internet-reachable (publicly_accessible = true) for local
# seeding and DMS access -- a private subnet in a second AZ would satisfy
# the AZ requirement but break reachability, since private subnets have no
# route to the Internet Gateway.
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name    = "multicloud-portfolio-public-b"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Connects the private subnet to its signpost
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# A second private subnet in a different AZ, added solely to satisfy RDS's
# requirement that a DB Subnet Group span at least two Availability Zones --
# not used for any other workload placement in this portfolio.
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.3.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name    = "multicloud-portfolio-private-b"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# The "wall socket" the VPN tunnel will eventually plug into on the AWS side.
# Created now, but not connected to anything yet — that happens in Phase 3.
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "multicloud-portfolio-vgw"
    Project = var.project_tag
    Task    = "01-cross-cloud-foundations"
  }
}

# Once the VPN exists, this automatically adds the route to Azure's network
# into the private subnet's signpost, without us hand-writing that route
resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private.id
}

# Also propagate the VPN route into the public route table -- needed because
# our connectivity test instance ended up in the public subnet (moved there
# earlier to give it internet access for SSM/EIC), and without this, the
# public subnet has no route to Azure's network at all, causing 100% packet
# loss despite the tunnel itself being genuinely up.
resource "aws_vpn_gateway_route_propagation" "public" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.public.id
}
