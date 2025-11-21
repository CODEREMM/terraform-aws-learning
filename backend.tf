terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-519nx22c"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dev"
  }
}