#!/bin/bash

# Deployment script for microservices CI/CD project
# Usage: ./scripts/deploy.sh <environment> [image_tag]

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Microservices Deployment Script"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "========================================="

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v ansible-playbook >/dev/null 2>&1 || { echo "Ansible is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }

# Step 1: Check AWS credentials
echo ""
echo "Step 1: Checking AWS credentials..."
aws sts get-caller-identity || { echo "AWS credentials not configured. Run 'aws configure'"; exit 1; }

# Step 2: Deploy infrastructure
echo ""
echo "Step 2: Deploying infrastructure with Terraform..."
cd "$PROJECT_ROOT/infrastructure/terraform/environments/$ENVIRONMENT"

if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found"
    echo "Copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

terraform init
terraform plan -out=tfplan
read -p "Apply Terraform plan? (yes/no): " -n 3 -r
echo
if [[ $REPLY =~ ^yes$ ]]; then
    terraform apply tfplan
else
    echo "Terraform deployment cancelled"
    exit 1
fi

# Get outputs
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
LB_DNS=$(terraform output -raw load_balancer_dns)

echo ""
echo "Infrastructure deployed successfully!"
echo "Jenkins IP: $JENKINS_IP"
echo "Load Balancer DNS: $LB_DNS"

# Step 3: Wait for instances to be ready
echo ""
echo "Step 3: Waiting for EC2 instances to be ready..."
sleep 60

# Step 4: Run Ansible provisioning
echo ""
echo "Step 4: Provisioning servers with Ansible..."
cd "$PROJECT_ROOT/ansible"

ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
    -e "environment=$ENVIRONMENT" \
    -e "image_tag=$IMAGE_TAG" \
    -e "ecr_registry=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com" \
    -e "jwt_secret=$(openssl rand -base64 32)"

# Step 5: Health check
echo ""
echo "Step 5: Running health checks..."
sleep 30

if curl -f "http://$LB_DNS/health" > /dev/null 2>&1; then
    echo "✓ API Gateway is healthy"
else
    echo "✗ API Gateway health check failed"
    exit 1
fi

if curl -f "http://$LB_DNS/health/services" > /dev/null 2>&1; then
    echo "✓ All services are healthy"
else
    echo "✗ Service health check failed"
    exit 1
fi

echo ""
echo "========================================="
echo "Deployment completed successfully!"
echo "========================================="
echo "API Gateway: http://$LB_DNS"
echo "Jenkins: http://$JENKINS_IP:8080"
echo ""
echo "Next steps:"
echo "1. Access Jenkins at http://$JENKINS_IP:8080"
echo "2. Test the API at http://$LB_DNS"
echo "3. View logs: ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>"
echo "========================================="
