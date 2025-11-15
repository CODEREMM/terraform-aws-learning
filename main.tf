provider "aws" {
  region = "us-east-1"
}

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
      Resource = aws_dynamodb_table.app_table.arn
    }]
  })
}

# Lambda function
resource "aws_lambda_function" "api_function" {
  filename         = "lambda_function.zip"
  function_name    = "${var.environment}-my-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime         = "python3.11"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      TABLE_NAME  = aws_dynamodb_table.app_table.name
    }
  }
}

# DynamoDB table
resource "aws_dynamodb_table" "app_table" {
  name           = "${var.environment}-app-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
  }
}

#REST API
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.environment}-my-api"
  description = "My First Terraform API"
}

#RESOURCE (/items)
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}
