variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "environment" {
  description = "Name of the environment"
  type        = string
}

variable "lambda_zip_path" {
    description = "Path to the lambda zip file"
    type = string
}

variable "table_name" {
    description = "DynameDB table name for the Lambda to access"
    type = string
}

variable "table_arn" {
    description = "DynamoDB table ARN for IAM permissions"
    type = string
}

variable "handler" {
    description = "Lambda function handler"
    type = string
    default = "index.handler"
}

variable "runtime" {
    description = "Lambda function runtime"
    type = string
    default = "python3.11"
}