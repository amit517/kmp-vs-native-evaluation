output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.news_backend.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.news_backend.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.news_backend.public_dns
}

output "api_endpoint" {
  description = "Full API endpoint URL"
  value       = "http://${aws_eip.news_backend.public_ip}:8080"
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "http://${aws_eip.news_backend.public_ip}:8080/health"
}

output "articles_endpoint" {
  description = "Articles API endpoint"
  value       = "http://${aws_eip.news_backend.public_ip}:8080/api/articles"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.news_backend.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/your-key.pem ec2-user@${aws_eip.news_backend.public_ip}"
}
