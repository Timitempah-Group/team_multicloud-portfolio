# The workspace's own IAM role -- SERVICE_MANAGED permission type means
# Grafana manages this role's trust policy automatically, rather than us
# hand-writing every permission it might need.
resource "aws_iam_role" "grafana" {
  name = "multicloud-portfolio-grafana-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "grafana.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# authentication_providers = ["AWS_SSO"] ties this workspace to the IAM
# Identity Center instance just enabled -- Grafana requires it for user
# sign-in, there is no separate "region" setting to configure here since
# Managed Grafana automatically finds the account's Identity Center instance.
resource "aws_grafana_workspace" "main" {
  name                     = "multicloud-portfolio-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["CLOUDWATCH", "PROMETHEUS"]

  tags = {
    Project = "multicloud-portfolio"
    Task    = "06-grafana-monitoring"
  }
}
