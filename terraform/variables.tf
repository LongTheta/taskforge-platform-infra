variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "taskforge"
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "owner" {
  description = "Owner or team"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for FinOps"
  type        = string
  default     = "platform"
}

variable "data_classification" {
  description = "Data classification"
  type        = string
  default     = "internal"
}

variable "lifecycle" {
  description = "Lifecycle stage"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_password" {
  description = "RDS master password. Use Secrets Manager or var in production."
  type        = string
  sensitive   = true
}

variable "eks_node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
