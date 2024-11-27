terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.77.0"
    }
  }
  backend "s3" {
    bucket = "server-infra-backup"
    key    = "state/terraform.tfstate"
    region = "us-east-2"
    # profile = "matheus"
  }

}

provider "aws" {
  # Configuration options
  # profile = "matheus"
  region = "us-east-2"
}
