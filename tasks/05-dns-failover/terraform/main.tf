# A real, publicly-delegated subdomain rather than a fake internal-only
# zone -- this genuinely resolves on the public internet once NS records
# are added at the parent domain's DNS provider (Cloudflare), unlike a
# .internal placeholder that only resolves by querying Route 53's
# nameservers directly.
resource "aws_route53_zone" "main" {
  name = "multicloud.timitempah.com"
}

# Health check against the AWS ALB directly over HTTP -- this is what
# gates whether the PRIMARY record is considered usable.
resource "aws_route53_health_check" "aws_primary" {
  fqdn              = data.terraform_remote_state.task3.outputs.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 2
  request_interval  = 10

  tags = {
    Project = "multicloud-portfolio"
    Task    = "05-dns-failover"
  }
}

# PRIMARY: an Alias record, not a CNAME. A CNAME cannot coexist with any
# other record type at the same name (a fundamental DNS rule, not a
# Route 53 quirk), and the SECONDARY record below is type A -- so PRIMARY
# must also resolve as type A. Alias records are Route 53's mechanism for
# pointing an A-type record at an AWS resource by name rather than a
# fixed IP, which is also the standard, recommended way to point Route 53
# at an ALB in production.
resource "aws_route53_record" "primary" {
  zone_id        = aws_route53_zone.main.zone_id
  name           = "app.multicloud.timitempah.com"
  type           = "A"
  set_identifier = "aws-primary"

  alias {
    name                   = data.terraform_remote_state.task3.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.task3.outputs.alb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.aws_primary.id

  failover_routing_policy {
    type = "PRIMARY"
  }
}

# SECONDARY: points at the Azure Application Gateway's IP. Only answers
# queries once Route 53 has marked the PRIMARY record unhealthy.
resource "aws_route53_record" "secondary" {
  zone_id        = aws_route53_zone.main.zone_id
  name           = "app.multicloud.timitempah.com"
  type           = "A"
  ttl            = 30
  set_identifier = "azure-secondary"
  records        = ["0.0.0.0"]

  failover_routing_policy {
    type = "SECONDARY"
  }
}
