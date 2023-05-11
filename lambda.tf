#
# Deploy a python lamda function
#
# For more info, see:
# - https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html
#



# Required trust policy that allows the Lambda service to assume the function's execution role.
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
# Lambda needs and allowing the Lambda service to assume it.
# More info at https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html
resource "aws_iam_role" "lambda_role" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", # Allows lambda to write CloudWatch logs
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",               # Allows request lambda to execute callback lambda
  ]
}


#
# The request lambda
#
# This lambda receives run task requests from TFC. It
# will confirm the request is valid (HMAC) and initiate
# the callback lambda, which will execute the actual run
# task action.
#
data "aws_ecr_repository" "request" {
  name = "run-task-poc-request"
}

data "aws_ecr_image" "request" {
  repository_name = data.aws_ecr_repository.request.name
  image_tag       = "latest"
}

resource "aws_lambda_function" "request" {
  function_name = "run_task_request"
  role          = aws_iam_role.lambda_role.arn
  image_uri     = "${data.aws_ecr_repository.request.repository_url}@${data.aws_ecr_image.request.image_digest}"
  package_type  = "Image"    # case sensitive
  architectures = ["x86_64"] # Must match the arch of the image

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

# Grant everyone permission to call the lambda's url
resource "aws_lambda_permission" "request" {
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.request.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}



#
# The callback lambda
#
# This lambda is called by the request lambda once the request payload 
# has been verified. It will perform any work required by the run task,
# asynchronously to TFC, and once complete will post the result back
# to the TFC run.
#
data "aws_ecr_repository" "callback" {
  name = "run-task-poc-callback"
}

data "aws_ecr_image" "callback" {
  repository_name = data.aws_ecr_repository.callback.name
  image_tag       = "latest"
}

resource "aws_lambda_function" "callback" {
  function_name = "run_task_callback"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 120 # seconds
  image_uri     = "${data.aws_ecr_repository.callback.repository_url}@${data.aws_ecr_image.callback.image_digest}"
  package_type  = "Image"    # case sensitive
  architectures = ["x86_64"] # Must match the arch of the image

  # The callback lambda downloads terraform plan details from TFC and needs an API
  # token to do that.
  # The API token in the run task request payload only has permission to report back against
  # the run task, so a separate token is needed.
  environment {
    variables = {
      TF_TOKEN = sensitive(var.terraform_token)
    }
  }
}
