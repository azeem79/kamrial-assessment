# CloudWatch Metric Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "kamrial-ecs-high-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when ECS CPU utilization exceeds 80% for 4 minutes."

  dimensions = {
    ClusterName = "kamrial-cluster"
  }
}