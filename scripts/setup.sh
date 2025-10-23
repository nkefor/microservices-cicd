#!/bin/bash

# Initial setup script for the microservices CI/CD project
# Usage: ./scripts/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Microservices CI/CD - Initial Setup"
echo "========================================="

# Check prerequisites
echo ""
echo "Checking prerequisites..."

MISSING_DEPS=0

command -v aws >/dev/null 2>&1 || { echo "✗ AWS CLI not found"; MISSING_DEPS=1; }
command -v terraform >/dev/null 2>&1 || { echo "✗ Terraform not found"; MISSING_DEPS=1; }
command -v ansible >/dev/null 2>&1 || { echo "✗ Ansible not found"; MISSING_DEPS=1; }
command -v docker >/dev/null 2>&1 || { echo "✗ Docker not found"; MISSING_DEPS=1; }
command -v node >/dev/null 2>&1 || { echo "✗ Node.js not found"; MISSING_DEPS=1; }
command -v python3 >/dev/null 2>&1 || { echo "✗ Python 3 not found"; MISSING_DEPS=1; }

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo "Please install missing dependencies and try again"
    echo "See README.md for installation instructions"
    exit 1
fi

echo "✓ All prerequisites installed"

# Step 1: Configure AWS
echo ""
echo "Step 1: AWS Configuration"
echo "=========================="
aws sts get-caller-identity || {
    echo "AWS credentials not configured"
    read -p "Configure AWS now? (yes/no): " -n 3 -r
    echo
    if [[ $REPLY =~ ^yes$ ]]; then
        aws configure
    else
        echo "Please run 'aws configure' before continuing"
        exit 1
    fi
}

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS Account ID: $AWS_ACCOUNT_ID"

# Step 2: Generate SSH key
echo ""
echo "Step 2: SSH Key Generation"
echo "=========================="
if [ ! -f ~/.ssh/microservices-cicd ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/microservices-cicd -N "" -C "microservices-cicd"
    echo "✓ SSH key generated at ~/.ssh/microservices-cicd"
else
    echo "✓ SSH key already exists at ~/.ssh/microservices-cicd"
fi

# Step 3: Create ECR repositories
echo ""
echo "Step 3: Creating ECR Repositories"
echo "=================================="
SERVICES=("api-gateway" "auth-service" "product-service" "order-service")

for service in "${SERVICES[@]}"; do
    if aws ecr describe-repositories --repository-names "microservices-cicd-dev-$service" >/dev/null 2>&1; then
        echo "✓ Repository microservices-cicd-dev-$service exists"
    else
        echo "Creating repository microservices-cicd-dev-$service..."
        aws ecr create-repository \
            --repository-name "microservices-cicd-dev-$service" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        echo "✓ Repository created"
    fi
done

# Step 4: Configure Terraform
echo ""
echo "Step 4: Terraform Configuration"
echo "================================"
cd "$PROJECT_ROOT/infrastructure/terraform/environments/dev"

if [ ! -f terraform.tfvars ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars

    # Get public IP
    PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

    # Get SSH public key
    SSH_PUBLIC_KEY=$(cat ~/.ssh/microservices-cicd.pub)

    # Update terraform.tfvars
    sed -i.bak "s|YOUR_IP/32|$PUBLIC_IP/32|g" terraform.tfvars
    sed -i.bak "s|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC...|$SSH_PUBLIC_KEY|g" terraform.tfvars

    echo "✓ terraform.tfvars created and configured"
    echo "  Your IP: $PUBLIC_IP"
    echo "  Please review and adjust if needed"
else
    echo "✓ terraform.tfvars already exists"
fi

# Step 5: Create .env file
echo ""
echo "Step 5: Environment Configuration"
echo "=================================="
cd "$PROJECT_ROOT"

if [ ! -f .env ]; then
    echo "Creating .env from example..."
    cp .env.example .env

    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i.bak "s|your-super-secret-jwt-key-change-this-in-production|$JWT_SECRET|g" .env

    echo "✓ .env file created with generated JWT secret"
else
    echo "✓ .env file already exists"
fi

# Step 6: Install project dependencies
echo ""
echo "Step 6: Installing Dependencies"
echo "================================"

echo "Installing Node.js dependencies..."
for service in api-gateway product-service; do
    if [ -d "$PROJECT_ROOT/services/$service" ]; then
        cd "$PROJECT_ROOT/services/$service"
        npm install
        echo "✓ $service dependencies installed"
    fi
done

echo "Installing Python dependencies..."
for service in auth-service order-service; do
    if [ -d "$PROJECT_ROOT/services/$service" ]; then
        cd "$PROJECT_ROOT/services/$service"
        pip3 install -r requirements.txt
        echo "✓ $service dependencies installed"
    fi
done

# Step 7: Test local Docker Compose
echo ""
echo "Step 7: Testing Local Setup"
echo "============================"
cd "$PROJECT_ROOT"

read -p "Test services locally with Docker Compose? (yes/no): " -n 3 -r
echo
if [[ $REPLY =~ ^yes$ ]]; then
    echo "Building and starting services..."
    docker-compose up -d

    echo "Waiting for services to start..."
    sleep 20

    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✓ Local deployment successful!"
        echo ""
        echo "Services running at:"
        echo "  API Gateway: http://localhost:3000"
        echo "  Auth Service: http://localhost:3001"
        echo "  Product Service: http://localhost:3002"
        echo "  Order Service: http://localhost:3003"
        echo ""
        read -p "Stop services? (yes/no): " -n 3 -r
        echo
        if [[ $REPLY =~ ^yes$ ]]; then
            docker-compose down
        fi
    else
        echo "✗ Local deployment health check failed"
        docker-compose logs
    fi
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review and adjust terraform.tfvars if needed"
echo "2. Run: ./scripts/deploy.sh dev"
echo "3. Configure Jenkins after deployment"
echo "4. Set up GitHub Actions secrets"
echo ""
echo "For more information, see README.md"
echo "========================================="
