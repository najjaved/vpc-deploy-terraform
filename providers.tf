# Configure AWS as the cloud provider in the us-east-1 region
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }

  backend "s3" {
    bucket         = "najma-s3-bucket-terraform-config-storage"  
    key            = "terraform.tfstate"          # The file path to store the state
    region         = "us-east-1"                
    encrypt        = true                        
    dynamodb_table = "terraform-state-lock"       # DynamoDB table for state locking
  }

}

provider "aws" {
  region = "us-east-1" #check if VPCs limit reached in this region
}
