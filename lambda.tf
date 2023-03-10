#
# Deploy a python lamda function
#
# For more info, see:
# - https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html
#



# Required trust policy that allows Lambda to assume the function's execution role.
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Execution role for the function, defining the permissions that the
# Lambda needs and allowing the Lambda function to assume it.
# More info at https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
resource "aws_iam_role" "lambda_role" {
  name                = "iam_for_lambda"
  assume_role_policy  = data.aws_iam_policy_document.lambda_trust_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}


# Packages up the python script to a zip that can be used by lambda
# See https://docs.aws.amazon.com/lambda/latest/dg/python-package.html
data "archive_file" "lambda_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda/main.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/lambda-function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "tfc-run-task"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  handler          = "main.lambda_handler" # File + function name
  runtime          = "python3.9"
}

resource "aws_lambda_function_url" "latest" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}
