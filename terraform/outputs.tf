output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}

output "ecr_api_url" {
  description = "The ECR repository URL for the API service"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_worker_url" {
  description = "The ECR repository URL for the Worker service"
  value       = aws_ecr_repository.worker.repository_url
}