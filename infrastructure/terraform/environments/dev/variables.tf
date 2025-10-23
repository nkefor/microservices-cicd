# Variables for Development Environment

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "microservices-cicd"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS IN PRODUCTION
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  # Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/microservices-cicd
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "microservices_instance_type" {
  description = "EC2 instance type for microservices servers"
  type        = string
  default     = "t3.small"
}

variable "microservices_count" {
  description = "Number of microservices servers to create"
  type        = number
  default     = 3
}
