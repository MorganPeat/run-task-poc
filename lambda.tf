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


#
# The request lambda
#
# This lambda receives run task requests from TFC. It
# will confirm the request is valid (HMAC) and initiate
# the callback lambda, which will execute the actual run
# task action.
#
resource "aws_lambda_function" "request" {
  function_name = "run_task_request"
  role          = aws_iam_role.lambda_role.arn

  # URI comes from the output of the packer build, once the image is pushed to ECR
  image_uri     = var.request_lambda_image_url
  package_type  = "Image" # case sensitive
  architectures = ["x86_64"]

  # This HMAC key allows the lambda to verify the payload.
  # It is also provided to the TFC run task itself.
  environment {
    variables = {
      HMAC_KEY = sensitive(random_pet.hmac_key.id)
    }
  }
}

# Expose the lambda via public-facing URL that TFC can call.
resource "aws_lambda_function_url" "request" {
  function_name      = aws_lambda_function.request.function_name
  authorization_type = "NONE"
}


#
# The callback lambda
#
# This lambda is called by the request lambda once the request payload 
# has been verified. It will perform any work required by the run task,
# asynchronously to TFC, and once complete will post the result back
# to the TFC run.
#
resource "aws_lambda_function" "callback" {
  function_name = "run_task_callback"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 120 # seconds

  # URI comes from the output of the packer build, once the image is pushed to ECR
  image_uri     = var.callback_lambda_image_url
  package_type  = "Image" # case sensitive
  architectures = ["x86_64"]
}
