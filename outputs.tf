# ==========================================
# MULTI-REGION API ENDPOINTS
# ==========================================

output "primary_api_endpoint" {
  description = "Primary region API endpoint (us-east-1)"
  value       = module.api_gateway_primary.api_endpoint
}

output "secondary_api_endpoint" {
  description = "Secondary region API endpoint (eu-west-1)"
  value       = module.api_gateway_secondary.api_endpoint
}

# ==========================================
# LAMBDA FUNCTIONS
# ==========================================

output "primary_lambda_function" {
  description = "Primary Lambda function name"
  value       = module.api_lambda_primary.function_name
}

output "secondary_lambda_function" {
  description = "Secondary Lambda function name"
  value       = module.api_lambda_secondary.function_name
}

# ==========================================
# DYNAMODB
# ==========================================

output "global_table_name" {
  description = "DynamoDB Global Table name"
  value       = aws_dynamodb_table.global_table.name
}

# ==========================================
# REGIONS
# ==========================================

output "primary_region" {
  description = "Primary deployment region"
  value       = var.primary_region
}

output "secondary_region" {
  description = "Secondary deployment region"
  value       = var.secondary_region
}