data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Defines what each new instance looks like when the ASG creates one.
# user_data installs a minimal web server and serves the instance's own ID
# and availability zone -- this is what makes load balancing visible: each
# refresh of the page can show a different instance answering.
resource "aws_launch_template" "web" {
  name_prefix   = "multicloud-task3-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
    cat > /var/www/html/index.html <<HTML
    <html>
      <body style="font-family: sans-serif; text-align: center; margin-top: 100px;">
        <h1>Multicloud Portfolio - Task 3</h1>
        <p>Answered by instance: <strong>$${INSTANCE_ID}</strong></p>
        <p>Availability Zone: <strong>$${AZ}</strong></p>
      </body>
    </html>
    HTML
    systemctl start httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "multicloud-task3-web"
      Project = "multicloud-portfolio"
      Task    = "03-aws-workload"
    }
  }
}
