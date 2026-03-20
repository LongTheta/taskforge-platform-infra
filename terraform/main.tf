# TaskForge Platform — AWS Infrastructure
# Supports: taskforge-backend, taskforge-security
# Compute: EKS | Data: RDS PostgreSQL | Secrets: Secrets Manager | GitOps: ArgoCD

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "taskforge-terraform-state"
  #   key            = "platform/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "taskforge-terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project            = var.project
      Environment        = var.environment
      Owner              = var.owner
      CostCenter         = var.cost_center
      ManagedBy          = "terraform"
      Purpose            = "taskforge-platform"
      DataClassification = var.data_classification
      Lifecycle          = var.lifecycle
    }
  }
}
