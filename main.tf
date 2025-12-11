#Create S3 bucket
resource "aws_s3_bucket" "demo_bucket" {
  bucket = "malik-demo-bucket2-2025"
  acl    = "private"
}

resource "aws_s3_bucket" "malik-demo-bucket2-2025" {
  bucket = "${var.bucket_prefix}-${var.environment}-123"

  tags = {
    Environment = var.environment
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


# Attach AWS managed policy for basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# IAM policy for Lambda to access DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = aws_dynamodb_table.global_table.arn
    }]
  })
}

# Lambda function
resource "aws_lambda_function" "api_function" {
  filename         = "lambda_function.zip"
  function_name    = "${var.environment}-my-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime          = "python3.11"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      TABLE_NAME  = aws_dynamodb_table.global_table.name
    }
  }
}

# DynamoDB Global table (Primary region with replica)
resource "aws_dynamodb_table" "global_table" {
  provider         = aws.primary
  name             = "${var.environment}-global-app-data"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  # Creates a replica in secondary region automatically 
  replica {
    region_name = var.secondary_region
  }

  tags = {
    Name        = "Global App Data Table"
    Environment = var.environment
  }
}

# ==========================================
# PRIMARY REGION (us-east-1)
# ==========================================

#Lambda module
module "api_lambda_primary" {
  source = "./modules/lambda.api"

  providers = {
    aws = aws.primary
  }

  function_name   = "${var.environment}-api-function-primary"
  environment     = "${var.environment}-primary"
  lambda_zip_path = "lambda_function.zip"
  table_name      = aws_dynamodb_table.global_table.name
  table_arn       = aws_dynamodb_table.global_table.arn
}

# API gateway primary module 
module "api_gateway_primary" {
  source = "./modules/api-gateway"

  providers = {
    aws = aws.primary
  }

  api_name             = "${var.environment}-api-primary"
  environment          = "${var.environment}-primary"
  lambda_invoke_arn    = module.api_lambda_primary.invoke_arn
  lambda_function_name = module.api_lambda_primary.function_name
}

# ==========================================
# SECONDARY REGION (eu-west-1)
# ==========================================
module "api_lambda_secondary" {
  source = "./modules/lambda.api"
  
  providers = {
    aws = aws.secondary
  }
  
  function_name   = "${var.environment}-api-function-secondary"
  environment     = "${var.environment}-secondary"
  lambda_zip_path = "lambda_function.zip"
  table_name      = aws_dynamodb_table.global_table.name
  table_arn       = aws_dynamodb_table.global_table.arn
}

module "api_gateway_secondary" {
  source = "./modules/api-gateway"
  
  providers = {
    aws = aws.secondary
  }
  
  api_name             = "${var.environment}-api-secondary"
  environment          = "${var.environment}-secondary"
  lambda_invoke_arn    = module.api_lambda_secondary.invoke_arn
  lambda_function_name = module.api_lambda_secondary.function_name
}


# REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.environment}-my-api"
  description = "My First Terraform API"
}

#RESOURCE (/items)
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# Method (GET /items)
resource "aws_api_gateway_method" "get_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_function.invoke_arn
}

#Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_function.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.items.id,
      aws_api_gateway_method.get_items.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

# ==========================================
# ROUTE 53 HEALTH CHECKS
# ==========================================

# Extract domain names from API endpoints
locals {
  # Remove https:// and everything after the domain
  primary_api_domain   = regex("https://([^/]+)", module.api_gateway_primary.api_endpoint)[0]
  secondary_api_domain = regex("https://([^/]+)", module.api_gateway_secondary.api_endpoint)[0]
  
  # Extract the path for health check
  primary_api_path     = regex("https://[^/]+(/.+)", module.api_gateway_primary.api_endpoint)[0]
  secondary_api_path   = regex("https://[^/]+(/.+)", module.api_gateway_secondary.api_endpoint)[0]
}
# Health check for primary region API
resource "aws_route53_health_check" "primary" {
  fqdn              = local.primary_api_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/dev-primary/items"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "${var.environment}-primary-api-health"
    Environment = var.environment
    Region      = var.primary_region
  }
}

# Health check for secondary region API
resource "aws_route53_health_check" "secondary" {
  fqdn              = local.secondary_api_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/dev-secondary/items"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "${var.environment}-secondary-api-health"
    Environment = var.environment
    Region      = var.secondary_region
  }
}

# ==========================================
# CLOUDWATCH ALARMS FOR HEALTH MONITORING
# ==========================================

# Alarm when primary API becomes unhealthy
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  alarm_name          = "${var.environment}-primary-api-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Primary API health check failed - possible outage in ${var.primary_region}"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  tags = {
    Environment = var.environment
    Severity    = "Critical"
  }
}

# Alarm when secondary API becomes unhealthy
resource "aws_cloudwatch_metric_alarm" "secondary_health" {
  alarm_name          = "${var.environment}-secondary-api-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Secondary API health check failed - possible outage in ${var.secondary_region}"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.secondary.id
  }

  tags = {
    Environment = var.environment
    Severity    = "Critical"
  }
}
