# ====================
#
# Lambda
#
# ====================
resource "aws_lambda_function" "scaleout_scaleup" {
  filename      = "./lambda_script/lambda_function.zip"
  function_name = "ec2_start_include_in_alb_rds_scaleup"
  role          = aws_iam_role.lambda_ec2_scaleout_rds_scaleup.arn
  handler       = "lambda_script/lambda_function.lambda_handler"
  # timeout 秒 最大に設定
  timeout     = 900
  runtime     = "python3.7"
  description = "アクセス集中時に停止しているEC2を起動しALBの配下に加える。RDSのインスタンスクラスを指定したクラスへ変更する"
  environment {
    variables = {
      "RDS_TARGET_INSTANCE_CLASS" : var.aws_target_rds_instance_class,
      "ALB_TARGET_GROUP_ARN" : aws_lb_target_group.example.arn,
      "INSTANCE_EC2_ID" : aws_instance.example_2.id,
      "INSTANCE_RDS_ID" : aws_db_instance.test_db.identifier,
      "REGION" : var.aws_region
    }
  }
}
