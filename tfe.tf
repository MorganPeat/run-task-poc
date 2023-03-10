resource "tfe_organization_run_task" "custom" {
  name        = "my-custom-run-task"
  url         = aws_lambda_function_url.latest.function_url
  enabled     = true
  description = "Custom run task running in a AWS lambda"
  hmac_key    = random_pet.hmac_key.id
}
