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

output "ecr_backend_url" {
  description = "ECR repository URL for taskforge-backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_security_url" {
  description = "ECR repository URL for taskforge-security"
  value       = aws_ecr_repository.security.repository_url
}

output "secrets_backend_arn" {
  description = "Secrets Manager ARN for backend secrets"
  value       = aws_secretsmanager_secret.backend.arn
}

output "secrets_security_arn" {
  description = "Secrets Manager ARN for security secrets"
  value       = aws_secretsmanager_secret.security.arn
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

output "kms_secrets_key_arn" {
  description = "KMS key ARN for Secrets Manager"
  value       = aws_kms_key.secrets.arn
}

output "kms_rds_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds.arn
}
