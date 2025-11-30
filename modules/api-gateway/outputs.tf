output "api_endpoint" {
    description = "API Gateway endpoint URL"
    value = "${aws_api_gateway_stage.api.invoke_url}/items"
}

output "api_id"{
    description = "API Gateway ID"
    value = aws_api_gateway_rest_api.api.id
}

output "api_arn" {
    description = "API Gateway ARN"
    value = aws_api_gateway_rest_api.api.arn
}