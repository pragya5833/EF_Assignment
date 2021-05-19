provider"aws"{
    region = "${var.region}"
}
resource "aws_instance" "insOne"{
    ami= "${var.amiId}"
    instance_type= "${var.instanceType}"
    tags={
        ins= "one"
    }
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# Define the Lambda function
resource "aws_lambda_function" "lambda-function" {
  function_name = "amiCreateandDelete"
  description   = "Lambda function for uploading lambda function"
  handler       = "${var.handler}"
  runtime       = "${var.runtime}"
  timeout       = 900
  s3_bucket         = "testassignmentef"
  s3_key            = "lambda.py.zip"
  role     = aws_iam_role.iam_for_lambda.arn
}
resource "aws_iam_policy" "accessEC2" {
  name        = "accessEC2"
  description = "IAM policy for lambda to access ec2"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_ec2" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.accessEC2.arn
}

# Define the CloudWatch schedule
resource "aws_cloudwatch_event_rule" "cloudwatch-event-rule-midnight-run" {
  name                = "amiCreateandDelete"
  description         = "Cloudwatch event rule to run every day at midnight for the ami Create and Delete."
  schedule_expression = "${var.schedule_midnight}"
}

# Define the CloudWatch target
resource "aws_cloudwatch_event_target" "cloudwatch-event-target" {
  rule = "amiCreateandDelete"
  arn  = "arn:aws:lambda:${var.region}:848417356303:function:amiCreateandDelete"
}

# Define the Lambda permission to run Lambda from CloudWatch
resource "aws_lambda_permission" "lambda-permission-cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "amiCreateandDelete"
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${var.region}:848417356303:rule/amiCreateandDelete"
}

