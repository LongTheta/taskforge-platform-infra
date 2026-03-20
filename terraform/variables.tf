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

variable "lifecycle_stage" {
  description = "Lifecycle stage (production, development, etc.)"
  type        = string
  default     = "production"
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network audit"
  type        = bool
  default     = true
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

variable "eks_endpoint_public_access" {
  description = "Enable public API endpoint for EKS. Set false for prod to restrict kubectl to VPC."
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for API audit logging"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC interface endpoints (ECR, Logs) to reduce NAT cost. S3 gateway endpoint always enabled."
  type        = bool
  default     = true
}
