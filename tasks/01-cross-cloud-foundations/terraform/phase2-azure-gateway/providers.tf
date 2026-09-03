terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Separate state file for this phase — keeps the slow-provisioning gateway
  # isolated from Phase 1's fast-apply networking resources
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task01/phase2.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "azurerm" {
  features {}
  subscription_id = "81197388-0d27-49a4-a47d-91730e333ca2"
  tenant_id       = "d286e9e8-3aa5-4cea-9477-4a04fc6560e1"
}

# Reads Phase 1's state file directly from S3 so this phase can reference
# resource group name, subnet ID, etc. without redeclaring them
data "terraform_remote_state" "phase1" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase1.tfstate"
    region = "eu-west-2"
  }
}
