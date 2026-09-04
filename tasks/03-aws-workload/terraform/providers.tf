terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task03/main.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Reads Task 1's VPC/subnets so this workload deploys into the same network
data "terraform_remote_state" "phase1" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase1.tfstate"
    region = "eu-west-2"
  }
}
