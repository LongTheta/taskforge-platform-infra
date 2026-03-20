output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, r in aws_ecr_repository.repos : k => r.repository_url }
}

output "ecr_backend_url" {
  description = "ECR repository URL for backend (when in ecr_repository_names)"
  value       = try(aws_ecr_repository.repos["backend"].repository_url, null)
}

output "ecr_security_url" {
  description = "ECR repository URL for security (when in ecr_repository_names)"
  value       = try(aws_ecr_repository.repos["security"].repository_url, null)
}

output "secrets_arns" {
  description = "Secrets Manager ARNs per workload"
  value       = { for k, s in aws_secretsmanager_secret.workloads : k => s.arn }
}

output "secrets_backend_arn" {
  description = "Secrets Manager ARN for backend (when in secrets_workload_names)"
  value       = try(aws_secretsmanager_secret.workloads["backend"].arn, null)
}

output "secrets_security_arn" {
  description = "Secrets Manager ARN for security (when in secrets_workload_names)"
  value       = try(aws_secretsmanager_secret.workloads["security"].arn, null)
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "eso_iam_role_arn" {
  description = "IRSA role ARN for External Secrets Operator"
  value       = aws_iam_role.eso.arn
}

output "lb_controller_iam_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.arn
}

output "ecr_push_policy_arn" {
  description = "IAM policy ARN for ECR push — attach to CI role"
  value       = aws_iam_policy.ecr_push.arn
}

output "kms_key_arns" {
  description = "KMS key ARNs (empty when use_customer_managed_kms=false)"
  value       = { for k, key in aws_kms_key.keys : k => key.arn }
}

output "kms_secrets_key_arn" {
  description = "KMS key ARN for Secrets Manager (null when use_customer_managed_kms=false)"
  value       = try(aws_kms_key.keys["secrets"].arn, null)
}

output "kms_rds_key_arn" {
  description = "KMS key ARN for RDS encryption (null when use_customer_managed_kms=false)"
  value       = try(aws_kms_key.keys["rds"].arn, null)
}
