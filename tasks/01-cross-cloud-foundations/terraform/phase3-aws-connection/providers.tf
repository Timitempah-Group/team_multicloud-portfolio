terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-senate-aws-portfolio"
    key            = "multicloud-portfolio/task01/phase3.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

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
