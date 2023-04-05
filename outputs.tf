output "lambda_url" {
  description = "The public URL of the request lambda function"
  value       = aws_lambda_function_url.request.function_url
}