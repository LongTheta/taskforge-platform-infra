# KMS — Customer-managed keys for Secrets Manager and RDS
# See docs/terraform-kms-patterns.md. for_each removes duplication.
# Uses data.aws_caller_identity.current from iam.tf

locals {
  account_id = data.aws_caller_identity.current.account_id
  kms_keys = {
    secrets = {
      description = "${var.project} Secrets Manager encryption"
      service     = "secretsmanager"
    }
    rds = {
      description = "${var.project} RDS encryption"
      service     = "rds"
    }
  }
}

resource "aws_kms_key" "keys" {
  for_each = var.use_customer_managed_kms ? local.kms_keys : {}

  description             = each.value.description
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Root"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "ServiceAccess"
        Effect    = "Allow"
        Principal = { Service = "${each.value.service}.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          StringEquals = { "kms:ViaService" = "${each.value.service}.${var.aws_region}.amazonaws.com" }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "keys" {
  for_each = var.use_customer_managed_kms ? local.kms_keys : {}

  name          = "alias/${var.project}-${var.environment}-${each.key}"
  target_key_id = aws_kms_key.keys[each.key].key_id
}
