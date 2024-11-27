terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.77.0"
    }
  }
}

provider "aws" {
  # Configuration options
  # profile = "matheus"
  region = "us-east-2"
}
