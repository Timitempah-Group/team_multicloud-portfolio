# The public-facing entry point -- deployed across both public subnets
# (both AZs) for the ALB's own availability requirement.
resource "aws_lb" "main" {
  name               = "multicloud-task3-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_id,
    data.terraform_remote_state.phase1.outputs.aws_public_subnet_b_id
  ]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "03-aws-workload"
  }
}

# The ALB's list of valid targets, continuously updated by health checks
resource "aws_lb_target_group" "main" {
  name     = "multicloud-task3-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.phase1.outputs.aws_vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "03-aws-workload"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
