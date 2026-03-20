# CloudWatch Alarms — RDS, EKS observability
# Naming: {resource}-{metric}-{threshold}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project}-${var.environment}-rds-cpu-utilization"
  comparison_operator  = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "CPUUtilization"
  namespace            = "AWS/RDS"
  period               = 300
  statistic            = "Average"
  threshold            = 80
  alarm_description    = "RDS CPU utilization exceeded 80%"
  treat_missing_data   = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project}-${var.environment}-rds-database-connections"
  comparison_operator  = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "DatabaseConnections"
  namespace            = "AWS/RDS"
  period               = 300
  statistic            = "Average"
  threshold            = 80
  alarm_description    = "RDS database connections high"
  treat_missing_data   = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-connections-alarm"
  }
}
