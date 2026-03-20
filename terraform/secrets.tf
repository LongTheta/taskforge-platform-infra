# Secrets Manager — For External Secrets Operator
# Store DATABASE_URL, SECRET_KEY, API_KEY
# ESO fetches and injects into K8s Secrets

resource "aws_secretsmanager_secret" "backend" {
  name = "${var.project}/${var.environment}/backend"
}

resource "aws_secretsmanager_secret_version" "backend" {
  secret_id = aws_secretsmanager_secret.backend.id
  secret_string = jsonencode({
    url        = "postgresql://${aws_db_instance.main.username}:${var.db_password}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
    secret_key = "REPLACE_WITH_OPENSSL_RAND_HEX_32_OUTPUT"
  })
  depends_on = [aws_db_instance.main]
}

resource "aws_secretsmanager_secret" "security" {
  name = "${var.project}/${var.environment}/security"
}

resource "aws_secretsmanager_secret_version" "security" {
  secret_id = aws_secretsmanager_secret.security.id
  secret_string = jsonencode({
    api_key = "REPLACE_WITH_STRONG_API_KEY"
  })
}

# IAM policy for External Secrets Operator — least privilege
# TODO: Use IRSA (IAM Roles for Service Accounts) for ESO pod instead of node role
# Only allow read of these secrets
resource "aws_iam_role_policy" "eso_secrets" {
  name   = "${var.project}-${var.environment}-eso-secrets"
  role   = aws_iam_role.eks_node.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.backend.arn,
          aws_secretsmanager_secret.security.arn
        ]
      }
    ]
  })
}
