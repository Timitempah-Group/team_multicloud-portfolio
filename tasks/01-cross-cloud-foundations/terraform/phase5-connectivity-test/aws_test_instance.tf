# Latest Amazon Linux 2023 AMI -- avoids hardcoding an AMI ID that goes
# stale or doesn't exist in this region
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# IAM role allowing this instance to be managed by SSM Session Manager --
# this is what lets us run commands on it with no SSH key and no open port 22
resource "aws_iam_role" "ssm" {
  name = "multicloud-test-instance-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "multicloud-test-instance-ssm-profile"
  role = aws_iam_role.ssm.name
}

# Security group: allow inbound ICMP (ping) only from Azure's address range --
# this is the actual traffic we're testing, nothing else is opened
resource "aws_security_group" "test" {
  name        = "multicloud-test-instance-sg"
  description = "Allows ICMP from Azure VNet CIDR for cross-cloud connectivity test"
  vpc_id      = data.terraform_remote_state.phase1.outputs.aws_vpc_id

  ingress {
    description = "ICMP from Azure VNet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [data.terraform_remote_state.phase1.outputs.azure_vnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

# The temporary test instance itself -- deployed in the private subnet
# (no public IP), reached only via SSM Session Manager
resource "aws_instance" "test" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.phase1.outputs.aws_public_subnet_id # Moved to public subnet -- private subnet has no internet route, so SSM Agent could not register
  vpc_security_group_ids = [aws_security_group.test.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name


  # Runs the connectivity test automatically at boot and prints a clearly
  # marked result block to the console log. Pivoted to this approach after
  # ruling out network routing, security groups, and IAM permissions for
  # both SSM Agent registration and EC2 Instance Connect -- remaining
  # hypotheses (AMI package, SSHD config) would require Serial Console
  # or VPC Interface Endpoints to verify, disproportionate for a one-shot
  # test on a disposable instance. Console output is an already-confirmed
  # working read path.
  user_data = <<-EOF
    #!/bin/bash
    echo "=== CONNECTIVITY TEST START ==="
    ping -c 4 10.200.1.4
    echo "=== CONNECTIVITY TEST END ==="
  EOF

  user_data_replace_on_change = true # Ensures user_data changes force a fresh boot, so the script actually executes

  tags = {
    Name    = "multicloud-connectivity-test-aws"
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}
