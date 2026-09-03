# This block tells Terraform which cloud providers we're using (AWS and Azure)
# and where to store the "state file" — the record of what Terraform has built.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # State file lives in S3, not on your laptop — this means Terraform always
  # knows the true current state even if you switch machines.
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task01/phase1.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# AWS provider — which AWS region to build in
provider "aws" {
  region = var.aws_region
}

# Azure provider — which subscription/tenant to build in.
# Set explicitly so Terraform never accidentally builds in the wrong subscription.
provider "azurerm" {
  features {}
  subscription_id = "81197388-0d27-49a4-a47d-91730e333ca2"
  tenant_id       = "d286e9e8-3aa5-4cea-9477-4a04fc6560e1"
}
