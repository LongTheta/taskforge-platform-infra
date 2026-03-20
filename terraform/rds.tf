# RDS PostgreSQL — Backend database
# Multi-AZ for prod; private subnets only; KMS encryption
# See docs/terraform-production-guardrails.md

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds"
  description = "RDS PostgreSQL — allow only from private subnets (EKS)"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    cidr_blocks = [for s in aws_subnet.private : s.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project}-${var.environment}"
  engine            = "postgres"
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  db_name  = var.rds_db_name
  username = var.rds_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period         = var.rds_backup_retention_period
  backup_window                   = var.rds_backup_window
  storage_encrypted               = true
  kms_key_id                      = var.use_customer_managed_kms ? aws_kms_key.keys["rds"].arn : null
  multi_az                        = var.rds_multi_az
  skip_final_snapshot             = var.rds_skip_final_snapshot
  final_snapshot_identifier       = var.rds_skip_final_snapshot ? null : "${var.project}-${var.environment}-final"
  enabled_cloudwatch_logs_exports = var.rds_cloudwatch_logs_exports
}
