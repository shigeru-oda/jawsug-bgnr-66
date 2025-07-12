terraform {
  backend "s3" {
    bucket  = "tfstate-shigeruoda-20250706093342"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
  required_version = "1.11.4"
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}
