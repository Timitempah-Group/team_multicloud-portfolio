# GitHub's OIDC provider already exists in this account -- OIDC providers
# are account-wide singletons keyed by issuer URL, shared across every repo
# and role that trusts them, so this references the existing one rather
# than trying to create a duplicate.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# The role GitHub Actions assumes. The trust policy's condition scopes this
# to ONLY this specific repository -- no other GitHub repo, even in the same
# account, could assume this role, regardless of what token it presents.
resource "aws_iam_role" "github_actions" {
  name = "multicloud-portfolio-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # This GitHub organization has OIDC subject claim customization
          # enabled, appending numeric org/repo IDs to the claim (e.g.
          # "repo:Timitempah-Group@297548596/team_multicloud-portfolio@1338876177:...")
          # rather than the plain "repo:OWNER/REPO:..." format most examples
          # assume. Discovered by printing the actual token claims during
          # a failed first run, rather than guessing at the format.
          "token.actions.githubusercontent.com:sub" = "repo:Timitempah-Group@*/team_multicloud-portfolio@*:*"
        }
      }
    }]
  })

  tags = {
    Project = "multicloud-portfolio"
    Task    = "10-cross-cloud-cicd"
  }
}

# Least-privilege policy: exactly what Task 3's Terraform needs to deploy
# (EC2/ALB/ASG networking) plus read/write access to the shared Terraform
# state backend -- deliberately not AdministratorAccess, unlike the
# devops-admin user used for manual work throughout this project.
resource "aws_iam_role_policy" "github_actions" {
  name = "task3-deploy-and-backend-access"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Task3Resources"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "TerraformStateBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::tfstate-senate-aws-portfolio",
          "arn:aws:s3:::tfstate-senate-aws-portfolio/*"
        ]
      },
      {
        Sid      = "TerraformLockTable"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = "arn:aws:dynamodb:eu-west-2:*:table/terraform-locks"
      }
    ]
  })
}
