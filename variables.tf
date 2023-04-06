variable "aws_role_arn" {
  description = "ARN of the role that the AWS terraform provider uses"
  type        = string
}

variable "tfe_organization" {
  type        = string
  description = "TFE organization that is to be configured"
  default     = "mp-demo-org"
}

variable "request_lambda_image_url" {
  type        = string
  description = "URL of the ECR image to use for the Request lambda"

  default = "303871294183.dkr.ecr.eu-west-2.amazonaws.com/run-task-poc-request:latest"
}

variable "callback_lambda_image_url" {
  type        = string
  description = "URL of the ECR image to use for the Request lambda"

  default = "303871294183.dkr.ecr.eu-west-2.amazonaws.com/run-task-poc-callback:latest"
}

variable "terraform_token" {
  type        = string
  description = "Terraform token that lambda uses to call back into TFE"
  sensitive   = true
}