# create repository to store docker image
resource "aws_ecr_repository" "lambda_selenium_container" {
  name                 = var.ecr_name
  image_tag_mutability = var.image_mutability

  image_scanning_configuration {
    scan_on_push = true
  }
}

# create iam role to run the function
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# give permission to create logs to the lambda role
resource "aws_iam_role_policy" "create_logs" {
  name = "create_logs"
  role = aws_iam_role.iam_for_lambda.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# add permission to write emails to lambda role
resource "aws_iam_role_policy" "email_write_policy" {
  name = "email_write_policy"
  role = aws_iam_role.iam_for_lambda.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# give necessary permissions to assume the role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# get image uri for image with tag latest
data "aws_ecr_image" "service_image" {
    repository_name = aws_ecr_repository.lambda_selenium_container.name
    image_tag       = var.docker_image_tag
}

# create lambda function to run the container
resource "aws_lambda_function" "lambda_selenium" {

  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri = data.aws_ecr_image.service_image.image_uri
  package_type = "Image"
  timeout = 30 # seconds
  environment {
    variables = {
      TO_EMAIL: var.to_email
      FROM_EMAIL: var.from_email
    }
  }
  ephemeral_storage { size = 5120 }
  tracing_config { mode = "PassThrough"}
  memory_size = 2560
  architectures = [ "x86_64" ]

}

# create cloud event rule that runs once an hour
resource "aws_cloudwatch_event_rule" "console" {
  name        = "tf-once-an-hour"
  description = "trigger lambda once an hour"
  schedule_expression = "rate(1 hour)"
}

# target the lambda function with the aws cloud watch rule
resource "aws_cloudwatch_event_target" "target_lambda_function" {
  target_id = "lambda_selenium"
  rule = aws_cloudwatch_event_rule.console.name
  arn       = aws_lambda_function.lambda_selenium.arn
}

# give cloud event rule permission to trigger lambda function
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_selenium.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.console.arn
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.lambda_selenium_container.repository_url
}
