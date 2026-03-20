# All customer-configurable choices are exposed here.
# Customers configure via .tfvars files; resource files consume variables only.

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "owner" {
  description = "Owner or team"
  type        = string
}

variable "cost_center" {
  description = "Cost center for FinOps"
  type        = string
}

variable "data_classification" {
  description = "Data classification"
  type        = string
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
}

variable "db_password" {
  description = "RDS master password. Use Secrets Manager or var in production."
  type        = string
  sensitive   = true
}

variable "eks_node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "eks_endpoint_public_access" {
  description = "Enable public API endpoint for EKS. Default false (secure); set true for kubectl from laptop."
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for API audit logging. Default false for cost; enable when justified."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC interface endpoints (ECR, Logs) to reduce NAT cost. S3 gateway endpoint always enabled."
  type        = bool
  default     = true
}

# EKS scaling — avoid hardcoding prod vs dev
variable "eks_desired_size" {
  description = "EKS node group desired size"
  type        = number
}

variable "eks_min_size" {
  description = "EKS node group minimum size"
  type        = number
}

variable "eks_max_size" {
  description = "EKS node group maximum size"
  type        = number
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

# VPC — NAT optional; 0 when VPC endpoints cover egress (ECR, S3, logs)
variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnet egress. Set false when VPC endpoints suffice."
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways when enabled (1 for dev, 2 for prod HA)"
  type        = number
}

variable "vpc_az_count" {
  description = "Number of AZs for subnets (1 for minimal dev, 2 for prod)"
  type        = number
}

variable "vpc_flow_log_retention_days" {
  description = "VPC Flow Log retention in CloudWatch"
  type        = number
  default     = 14
}

# RDS
variable "rds_db_name" {
  description = "RDS database name"
  type        = string
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
}

variable "rds_engine_version" {
  description = "RDS PostgreSQL engine version"
  type        = string
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention (days); 0 for dev"
  type        = number
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on destroy; false for prod"
  type        = bool
  default     = true
}

# ECR
variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability (MUTABLE or IMMUTABLE). Default IMMUTABLE for security."
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_lifecycle_max_image_count" {
  description = "ECR lifecycle policy — keep last N images"
  type        = number
}

# CloudTrail
variable "cloudtrail_log_retention_days" {
  description = "CloudTrail S3 lifecycle expiration (days)"
  type        = number
}

variable "cloudtrail_include_global_service_events" {
  description = "Include global service events (e.g. IAM) in CloudTrail"
  type        = bool
  default     = true
}

variable "cloudtrail_is_multi_region" {
  description = "Create multi-region CloudTrail trail"
  type        = bool
  default     = false
}

variable "cloudtrail_enable_log_file_validation" {
  description = "Enable CloudTrail log file integrity validation"
  type        = bool
  default     = true
}

# Observability
variable "alarm_period_seconds" {
  description = "CloudWatch alarm evaluation period"
  type        = number
}

variable "rds_cpu_alarm_threshold" {
  description = "RDS CPU alarm threshold (percent)"
  type        = number
}

variable "rds_connections_alarm_threshold" {
  description = "RDS database connections alarm threshold"
  type        = number
}

# --- Additional configurable choices (no resource edits required) ---

variable "tags" {
  description = "Additional tags to merge with default_tags"
  type        = map(string)
  default     = {}
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ for HA"
  type        = bool
}

variable "rds_backup_window" {
  description = "RDS daily backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "ecr_repository_names" {
  description = "ECR repository names (each becomes {project}-{name})"
  type        = list(string)
  default     = ["backend", "security"]
}

variable "secrets_workload_names" {
  description = "Secrets Manager workload names (must include workloads needing secrets)"
  type        = list(string)
  default     = ["backend", "security"]
}

variable "secrets_workload_placeholders" {
  description = "Placeholder values per workload secret keys. Keys must match secrets_workload_names. Replace after first apply."
  type        = map(map(string))
  sensitive   = true
  default = {
    backend  = { secret_key = "REPLACE_WITH_OPENSSL_RAND_HEX_32_OUTPUT" }
    security = { api_key = "REPLACE_WITH_STRONG_API_KEY" }
  }
}

variable "secrets_workloads_with_db_url" {
  description = "Workload names that receive RDS connection URL in their secret"
  type        = list(string)
  default     = ["backend"]
}

variable "enable_observability_alarms" {
  description = "Enable CloudWatch alarms for EKS and RDS. Default false for cost; enable for production."
  type        = bool
  default     = false
}

variable "eks_control_plane_5xx_alarm_threshold" {
  description = "EKS control plane 5xx alarm threshold"
  type        = number
  default     = 1
}

variable "alarm_evaluation_periods" {
  description = "CloudWatch alarm evaluation periods"
  type        = number
  default     = 2
}

variable "cloudtrail_noncurrent_version_days" {
  description = "CloudTrail S3 noncurrent version expiration (days)"
  type        = number
  default     = 30
}

variable "eks_node_group_name" {
  description = "EKS node group name"
  type        = string
  default     = "default"
}

variable "vpc_flow_log_traffic_type" {
  description = "VPC Flow Log traffic type (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
}

variable "rds_port" {
  description = "RDS port"
  type        = number
  default     = 5432
}

variable "use_customer_managed_kms" {
  description = "Use customer-managed KMS for RDS and Secrets Manager. Default false for cost; enable for compliance."
  type        = bool
  default     = false
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window (days)"
  type        = number
  default     = 7
}

variable "rds_cloudwatch_logs_exports" {
  description = "RDS CloudWatch log types to export (e.g. postgresql, upgrade)"
  type        = list(string)
  default     = ["postgresql"]
}

variable "ecr_scan_on_push" {
  description = "Enable ECR image scan on push"
  type        = bool
  default     = true
}

variable "eso_service_account_namespace" {
  description = "Kubernetes namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_name" {
  description = "Kubernetes service account for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "lb_controller_service_account_namespace" {
  description = "Kubernetes namespace for AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "lb_controller_service_account_name" {
  description = "Kubernetes service account for AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}
