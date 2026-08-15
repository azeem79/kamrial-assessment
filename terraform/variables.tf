variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Primary AWS region for deployment"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Target deployment environment (e.g., staging, production). Enables Terraform workspace isolation."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the primary VPC"
}

variable "app_name" {
  type        = string
  default     = "kamrial"
  description = "Application name tag prefix"
}