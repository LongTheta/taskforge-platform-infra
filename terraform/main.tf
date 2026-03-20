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
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # Remote state: terraform init -backend-config=backend.hcl
  # Copy backend.hcl.example to backend.hcl and set bucket, key, region, dynamodb_table.
  # Bootstrap backend: ./scripts/bootstrap-backend.sh
  backend "s3" {}
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
      Lifecycle          = var.lifecycle_stage
    }
  }
}
