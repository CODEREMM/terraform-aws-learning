terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Primary Region
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# Secondary Region
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}

# Default provider (for Route 53)
provider "aws" {
  region = var.primary_region
}