output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}
output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "ecr_repository_url" {
  description = "URL of the ECR"
  value       = aws_ecr_repository.ecr_rep.repository_url
}

output "alb_dns_name" {
  description = "DNS of the Application Load balancer"
  value       = aws_lb.app_lb.dns_name
}