# Outputs for Development Environment

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "microservices_public_ips" {
  description = "Microservices servers public IPs"
  value       = aws_instance.microservices[*].public_ip
}

output "microservices_private_ips" {
  description = "Microservices servers private IPs"
  value       = aws_instance.microservices[*].private_ip
}

output "load_balancer_dns" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "api_gateway_url" {
  description = "API Gateway URL via Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ssh_command_jenkins" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ~/.ssh/microservices-cicd ubuntu@${aws_instance.jenkins.public_ip}"
}

output "ssh_commands_microservices" {
  description = "SSH commands to connect to microservices servers"
  value = [
    for instance in aws_instance.microservices :
    "ssh -i ~/.ssh/microservices-cicd ubuntu@${instance.public_ip}"
  ]
}
