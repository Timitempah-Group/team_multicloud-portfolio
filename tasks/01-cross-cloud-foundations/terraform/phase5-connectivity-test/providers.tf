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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task01/phase5-test.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "azurerm" {
  features {}
  subscription_id = "81197388-0d27-49a4-a47d-91730e333ca2"
  tenant_id       = "d286e9e8-3aa5-4cea-9477-4a04fc6560e1"
}

data "terraform_remote_state" "phase1" {
  backend = "s3"
  config = {
    bucket = "tfstate-senate-aws-portfolio"
    key    = "multicloud-portfolio/task01/phase1.tfstate"
    region = "eu-west-2"
  }
}
