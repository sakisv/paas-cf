resource "aws_cloudwatch_metric_alarm" "ddos_detected_apps_lb" {
  alarm_name          = "ddos_detected_apps_lb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Shield Advanced reports a DDoS event is underway"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.ddos_detected.arn]
  dimensions = {
    ResourceArn = aws_lb.cf_router_app_domain.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_detected_sys_lb" {
  alarm_name          = "ddos_detected_sys_lb"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "4"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Shield Advanced reports a DDoS event is underway"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.ddos_detected.arn]
  dimensions = {
    ResourceArn = aws_lb.cf_router_system_domain.arn
  }
}

resource "aws_sns_topic" "ddos_detected" {
  name = "ddos_detected"
}

resource "aws_sns_topic_subscription" "ddos_detected" {
  topic_arn = aws_sns_topic.ddos_detected.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ddos_lambda.arn
}
