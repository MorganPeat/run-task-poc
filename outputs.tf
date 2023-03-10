output "lambda_url" {
  description = "The public URL of the lambda function"
  value       = aws_lambda_function_url.latest.function_url
}