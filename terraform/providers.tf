terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.11.0"
  backend "s3" {
    bucket  = "terraform-state-bucket-654654586547"
    key     = "strapi-ecs-fargate/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
    # Native state locking is enabled if S3 bucket has object lock and versioning enabled
  }
}

provider "aws" {
  region = var.region
}
