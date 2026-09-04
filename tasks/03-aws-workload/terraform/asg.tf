# The Auto Scaling Group -- deployed into the private subnets (both AZs),
# so instances are never directly internet-reachable, only via the ALB.
resource "aws_autoscaling_group" "web" {
  name                = "multicloud-task3-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = [
    data.terraform_remote_state.phase1.outputs.aws_private_subnet_id,
    data.terraform_remote_state.phase1.outputs.aws_private_subnet_b_id
  ]
  target_group_arns = [aws_lb_target_group.main.arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "multicloud-task3-web"
    propagate_at_launch = true
  }
}
