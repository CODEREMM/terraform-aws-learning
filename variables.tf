variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-1"
}
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_prefix" {
  description = "malik-demo-bucket2-2025"
  type        = string
}