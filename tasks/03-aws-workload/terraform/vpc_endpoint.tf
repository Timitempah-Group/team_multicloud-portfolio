# Amazon Linux package repositories are hosted on S3. Rather than adding a
# NAT Gateway (real ongoing cost) just to let private-subnet instances reach
# the internet for dnf install, a free S3 Gateway Endpoint gives them a
# direct, private route to S3 specifically -- sufficient for package
# installation without any actual internet exposure.
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = data.terraform_remote_state.phase1.outputs.aws_vpc_id
  service_name = "com.amazonaws.eu-west-2.s3"

  route_table_ids = [
    data.terraform_remote_state.phase1.outputs.aws_private_route_table_id
  ]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "03-aws-workload"
  }
}
