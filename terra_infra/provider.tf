terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
    backend "s3" {
        bucket = "tf-bucket-ffp"
        key    = "dev/v1/23jan.tfstate"
        region = "eu-west-1"
        dynamodb_table = "terraform_locks"
        profile = "pff"
    }
}

# Configure the AWS Provider
provider "aws" {
    profile = "pff"
    region = "eu-west-1"
}

