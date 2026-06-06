variable "aws_region" {
  description = "AWS region for deployment (Europe)"
  type        = string
  default     = "eu-central-1"  # Frankfurt - closest to most of Europe
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "kmp-news-backend"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "docker_image" {
  description = "Docker image to deploy (can be ECR URI or Docker Hub image)"
  type        = string
  default     = "kmp-news-backend:latest"
}
