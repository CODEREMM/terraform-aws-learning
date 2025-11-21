output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.malik-demo-bucket2-2025.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.malik-demo-bucket2-2025.arn
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value	      = aws_iam_role.lambda_role.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.app_table.name
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       ="${aws_api_gateway_stage.api_stage.invoke_url}/items"
}

# Output the bucket name 
output "state_bucket_name" {
  description = "Name of the S3 bucket"
  value = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value = aws_dynamodb_table.terraform_state_lock.id
}