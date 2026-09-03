terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task01/phase4.tfstate"
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

# AWS provider is only needed here to read the PSK from Secrets Manager --
# no AWS resources are created in this phase, this is a read-only lookup
provider "aws" {
  region = "eu-west-2"
}

data "terraform_remote_state" "phase1" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase1.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase2.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "phase3" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase3.tfstate"
    region = "eu-west-2"
  }
}
