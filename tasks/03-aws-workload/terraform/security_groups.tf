# ALB security group -- allows inbound HTTP from anywhere, since this is
# the public-facing entry point
resource "aws_security_group" "alb" {
  name        = "multicloud-task3-alb-sg"
  description = "Allows inbound HTTP to the ALB from anywhere"
  vpc_id      = data.terraform_remote_state.phase1.outputs.aws_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "03-aws-workload"
  }
}

# Instance security group -- only allows HTTP from the ALB itself, not from
# the internet directly. This is what makes the private-subnet placement
# meaningful: instances are never directly reachable, only via the ALB.
resource "aws_security_group" "instances" {
  name        = "multicloud-task3-instances-sg"
  description = "Allows HTTP only from the ALB security group"
  vpc_id      = data.terraform_remote_state.phase1.outputs.aws_vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "03-aws-workload"
  }
}
