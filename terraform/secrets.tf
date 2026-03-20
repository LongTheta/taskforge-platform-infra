# Secrets Manager — For External Secrets Operator
# Store DATABASE_URL, SECRET_KEY, API_KEY per workload
# All workloads configured via var.secrets_workload_names and var.secrets_workload_placeholders

locals {
  secrets_workloads = toset(var.secrets_workload_names)
}

resource "aws_secretsmanager_secret" "workloads" {
  for_each   = local.secrets_workloads
  name       = "${var.project}/${var.environment}/${each.key}"
  kms_key_id = try(aws_kms_key.keys["secrets"].arn, null)
}

resource "aws_secretsmanager_secret_version" "workloads" {
  for_each = local.secrets_workloads

  secret_id = aws_secretsmanager_secret.workloads[each.key].id
  secret_string = jsonencode(
    contains(var.secrets_workloads_with_db_url, each.key)
    ? merge(
      { url = "postgresql://${aws_db_instance.main.username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.rds_db_name}" },
      lookup(var.secrets_workload_placeholders, each.key, {})
    )
    : lookup(var.secrets_workload_placeholders, each.key, {})
  )
  depends_on = [aws_db_instance.main]
}

# ESO IAM: See iam.tf — IRSA role for External Secrets Operator
