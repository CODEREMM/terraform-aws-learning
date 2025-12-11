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

# ==========================================
# HEALTH CHECK OUTPUTS
# ==========================================

# ID's
output "primary_health_check_id" {
  description = "Primary region health check ID"
  value = aws_route53_health_check.primary.id
}

output "secondary_health_check_id" {
  description = "Secondary region health check ID"
  value = aws_route53_health_check.secondary.id
}

# URL's
output "primary_health_check_url" {
  description = "URL to view primary health check in AWS Console"
  value       = "https://${var.primary_region}.console.aws.amazon.com/route53/healthchecks/home?region=${var.primary_region}#/details/${aws_route53_health_check.primary.id}"
}

output "secondary_health_check_url" {
  description = "URL to view secondary health check in AWS Console"
  value       = "https://${var.secondary_region}.console.aws.amazon.com/route53/healthchecks/home?region=${var.secondary_region}#/details/${aws_route53_health_check.secondary.id}"
}
# AlARMS
output "primary_health_alarm" {
  description = "Primary region health alarm name"
  value       = aws_cloudwatch_metric_alarm.primary_health.alarm_name
}

output "secondary_health_alarm" {
  description = "Secondary region health alarm name"
  value       = aws_cloudwatch_metric_alarm.secondary_health.alarm_name
}