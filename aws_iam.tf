# ====================
#
# IAM
#
# ====================
resource "aws_iam_role" "lambda_ec2_scaleout_rds_scaleup" {
  name = "lambda_ec2_scaleout_rds_scaleup"
  tags = {
    Name = "example"
  }
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}
resource "aws_iam_policy" "lambda" {
  name        = "test-policy"
  description = "lambda用"
  tags = {
    Name = "example"
  }
  policy = data.aws_iam_policy_document.lambda_use.json
}
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.lambda_ec2_scaleout_rds_scaleup.name
  policy_arn = aws_iam_policy.lambda.arn
}
data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy_document" "lambda_use" {
  source_json = data.aws_iam_policy.lambda_basic_execution.policy
  statement {
    sid = "1"
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "elasticloadbalancing:RegisterTargets",
      "rds:Describe*",
      "rds:ModifyDBInstance",
      #"cloudwatch:DescribeAlarms",
      #"cloudwatch:GetMetricStatistics",
      #"cloudwatch:PutMetricAlarm",
      #"cloudwatch:DeleteAlarms",
      #"logs:DescribeLogStreams",
      #"logs:GetLogEvents",
      #"outposts:GetOutpostInstanceTypes"
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "pi:*",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:pi:*:*:metrics/rds/*",
    ]


  }

  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"

      values = [
        "rds.amazonaws.com",
        "rds.application-autoscaling.amazonaws.com",
      ]
    }
  }
}
