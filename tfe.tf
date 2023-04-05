#
# Adds a run task to our TFE org and configures
# it to hash request payloads with the provided
# HMAC key
#
resource "tfe_organization_run_task" "custom" {
  name        = "my-custom-run-task"
  url         = aws_lambda_function_url.request.function_url # Public-facing URL of the request lambda
  enabled     = true
  description = "Custom run task running in a AWS lambda"
  hmac_key    = random_pet.hmac_key.id # Will create HMAC digest of the payload, for verification in the lambda
}
