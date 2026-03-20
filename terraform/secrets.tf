# Secrets Manager — For External Secrets Operator
# Store DATABASE_URL, SECRET_KEY, API_KEY
# Encrypted with customer-managed KMS

resource "aws_secretsmanager_secret" "backend" {
  name       = "${var.project}/${var.environment}/backend"
  kms_key_id = aws_kms_key.secrets.arn
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
  name       = "${var.project}/${var.environment}/security"
  kms_key_id = aws_kms_key.secrets.arn
}

resource "aws_secretsmanager_secret_version" "security" {
  secret_id = aws_secretsmanager_secret.security.id
  secret_string = jsonencode({
    api_key = "REPLACE_WITH_STRONG_API_KEY"
  })
}

# ESO IAM: See iam.tf — IRSA role for External Secrets Operator
