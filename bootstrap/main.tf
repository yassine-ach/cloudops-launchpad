terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "cloudops-launchpad-tfstate-yassine-ach"

  tags = {
    Name        = "cloudops-launchpad-tfstate"
    #Environment = "Dev"
  }
}