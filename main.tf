resource "aws_iam_role" "ec2_check_role" {
    name = "ec2_check_role"
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

resource "aws_iam_role_policy" "ec2_check_policy" {
    role = "${aws_iam_role.ec2_check_role}"

  policy = <<EOF
    {
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":"*"
      },
      {
         "Action":[
            "sts:*"
         ],
         "Effect":"Allow",
         "Resource": [
           "*"
         ]
      }
   ]
    }
    EOF
}

resource "aws_lambda_function" "ec2_check_lambda" {
    filename    = "./lambdas/ec2_shutdown.pt"
    function_name = "ec2-shutdown-function"
    role = "${aws_iam_role_policy.ec2_check_policy}"
    handler = lambda_handler
    source_code_hash = "${base54sha256("lambdas/ec2_shutdown.py")}"
    runtime = "python3.8"
    timeout = "60"
    memory_size = "128"

    environment {
        variables = {
            TEST = ""
        }
    }
}

resource "aws_cloudwatch_event_rule" "every_three_hours" {
    name    = "every-three-hours"
    schedule_expression = "rate(3 hours)"
}

resource "aws_cloudwatch_event_targer" "ec2_check_targer" {
    rule = "${aws.cloudwatch_event_rule.every_three_hours.name}"
    target_id = "${ec2_check_lambda}"
    arn = "${ec2_check_lambda.arb}"
}

