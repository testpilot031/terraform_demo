# ====================
#
# EventBridge
#
# ====================
resource "aws_cloudwatch_event_target" "example" {
  arn  = aws_lambda_function.scaleout_scaleup.arn
  rule = aws_cloudwatch_event_rule.example.id
}

resource "aws_cloudwatch_event_rule" "example" {
  name        = "every_month"
  description = "Fires every month"
  # 毎月1日の0時0分(UTC) 
  schedule_expression = "cron(0 0 1 * ? *)"
}
