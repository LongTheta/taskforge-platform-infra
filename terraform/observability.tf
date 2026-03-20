# CloudWatch Alarms — EKS, RDS observability
# Only created when enable_observability_alarms=true; all thresholds configurable via variables

locals {
  alarm_definitions = var.enable_observability_alarms ? {
    eks-control-plane-5xx = {
      namespace           = "AWS/EKS"
      metric_name         = "apiserver_request_total_5XX"
      statistic           = "Sum"
      comparison_operator = "GreaterThanThreshold"
      threshold           = var.eks_control_plane_5xx_alarm_threshold
      evaluation_periods  = var.alarm_evaluation_periods
      description         = "EKS control plane 5xx errors"
      dimensions          = { ClusterName = aws_eks_cluster.main.name }
    }
    rds-cpu = {
      namespace           = "AWS/RDS"
      metric_name         = "CPUUtilization"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = var.rds_cpu_alarm_threshold
      evaluation_periods  = var.alarm_evaluation_periods
      description         = "RDS CPU utilization exceeded ${var.rds_cpu_alarm_threshold}%"
      dimensions          = { DBInstanceIdentifier = aws_db_instance.main.id }
    }
    rds-connections = {
      namespace           = "AWS/RDS"
      metric_name         = "DatabaseConnections"
      statistic           = "Average"
      comparison_operator = "GreaterThanThreshold"
      threshold           = var.rds_connections_alarm_threshold
      evaluation_periods  = var.alarm_evaluation_periods
      description         = "RDS database connections high"
      dimensions          = { DBInstanceIdentifier = aws_db_instance.main.id }
    }
  } : {}
}

resource "aws_cloudwatch_metric_alarm" "alarms" {
  for_each = local.alarm_definitions

  alarm_name          = "${var.project}-${var.environment}-${each.key}"
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  statistic           = each.value.statistic
  period              = var.alarm_period_seconds
  comparison_operator = each.value.comparison_operator
  threshold           = each.value.threshold
  evaluation_periods  = var.alarm_evaluation_periods
  alarm_description   = each.value.description
  treat_missing_data  = "notBreaching"
  dimensions          = each.value.dimensions
}
