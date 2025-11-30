output "function_name" {
    description = "Name of the function"
    value = aws_lambda_function.function.function_name
}

output "function_arn" {
    description = "ARN of the function"
    value = aws_lambda_function.function.arn
}

output "invoke_arn" {
    description = "Invoke API for API Gateway integration"
    value = aws_lambda_function.function.invoke_arn
}

output "role_arn" {
    description = "ARN of the Lambda execution role"
    value = aws_iam_role.lambda_role.arn
}