variable "aws_role_arn" {
  description = "ARN of the role that the AWS terraform provider uses"
  type        = string
}

variable "tfe_organization" {
  type        = string
  description = "TFE organization that is to be configured"
  default     = "mp-demo-org"
}