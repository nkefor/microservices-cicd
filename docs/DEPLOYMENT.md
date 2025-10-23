# Deployment Guide

Complete step-by-step guide for deploying the microservices CI/CD infrastructure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [Application Deployment](#application-deployment)
5. [CI/CD Configuration](#cicd-configuration)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **AWS CLI** v2.x or higher
- **Terraform** v1.5.0 or higher
- **Ansible** v2.14 or higher
- **Docker** v24.0 or higher
- **Node.js** v18.x or higher
- **Python** v3.11 or higher
- **Git** v2.x or higher

### AWS Account Requirements

- Active AWS account with billing enabled
- IAM user with administrator access (or specific permissions)
- AWS CLI configured with credentials
- Sufficient EC2, VPC, and ELB limits

### Local Machine Requirements

- Linux, macOS, or WSL on Windows
- At least 4GB free disk space
- Internet connection

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd microservices-cicd
```

### 2. Run Setup Script

The setup script automates initial configuration:

```bash
./scripts/setup.sh
```

This script will:
- Verify prerequisites
- Configure AWS credentials
- Generate SSH key pair
- Create ECR repositories
- Configure Terraform variables
- Generate environment variables
- Install project dependencies
- Test local Docker Compose setup

### 3. Manual Configuration (if not using setup script)

#### Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

#### Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/microservices-cicd
```

#### Create Terraform Variables

```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region  = "us-east-1"
project_name = "microservices-cicd"
environment = "dev"

ssh_public_key = "<paste your ~/.ssh/microservices-cicd.pub content>"
allowed_ssh_cidr = ["<your-ip>/32"]  # Get with: curl https://checkip.amazonaws.com

jenkins_instance_type      = "t3.medium"
microservices_instance_type = "t3.small"
microservices_count        = 3
```

#### Create Environment File

```bash
cd <project-root>
cp .env.example .env
```

Generate JWT secret:

```bash
openssl rand -base64 32
```

Update `.env` with the generated secret.

## Infrastructure Deployment

### Option 1: Automated Deployment

Use the deployment script:

```bash
./scripts/deploy.sh dev
```

### Option 2: Manual Deployment

#### Step 1: Deploy Infrastructure with Terraform

```bash
cd infrastructure/terraform/environments/dev

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

Save the outputs:

```bash
terraform output > outputs.txt
```

#### Step 2: Wait for EC2 Instances

Wait 2-3 minutes for instances to fully boot and run user data scripts.

#### Step 3: Provision Servers with Ansible

```bash
cd ../../../../ansible

# Test connectivity
ansible all -i inventory/hosts.ini -m ping

# Run full provisioning
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

This will:
- Update packages on all servers
- Install and configure Docker
- Set up Jenkins server
- Configure microservices servers
- Set up monitoring and logging

## Application Deployment

### Option 1: Deploy via Jenkins

1. Access Jenkins at `http://<jenkins-ip>:8080`

2. Get initial admin password:
   ```bash
   ssh -i ~/.ssh/microservices-cicd ubuntu@<jenkins-ip>
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. Complete Jenkins setup wizard

4. Install required plugins:
   - Docker Pipeline
   - AWS Credentials
   - Ansible

5. Configure credentials:
   - AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
   - SSH key for deployment

6. Create Pipeline:
   - New Item → Pipeline
   - Pipeline script from SCM
   - Git repository URL
   - Script path: `Jenkinsfile`

7. Run the pipeline

### Option 2: Deploy with GitHub Actions

1. Configure GitHub repository secrets:
   ```
   AWS_ACCESS_KEY_ID
   AWS_SECRET_ACCESS_KEY
   AWS_ACCOUNT_ID
   SSH_PRIVATE_KEY
   JWT_SECRET
   ```

2. Push code to trigger workflow:
   ```bash
   git add .
   git commit -m "Initial deployment"
   git push origin main
   ```

3. Monitor workflow in GitHub Actions tab

### Option 3: Manual Docker Deployment

Build and push images:

```bash
./scripts/build-and-push.sh v1.0.0
```

Deploy with Ansible:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
  -e "image_tag=v1.0.0" \
  -e "ecr_registry=<account-id>.dkr.ecr.us-east-1.amazonaws.com" \
  -e "jwt_secret=$(openssl rand -base64 32)"
```

## CI/CD Configuration

### Jenkins Configuration

1. **Configure AWS Credentials**:
   - Manage Jenkins → Manage Credentials
   - Add AWS credentials
   - ID: `aws-credentials`

2. **Configure SSH Key**:
   - Add SSH private key for server access
   - ID: `deployment-key`

3. **Install Ansible**:
   ```bash
   ssh -i ~/.ssh/microservices-cicd ubuntu@<jenkins-ip>
   sudo pip3 install ansible boto3
   ```

4. **Create Pipeline Job**:
   - Configure webhook for automatic builds
   - Set parameters (ENVIRONMENT, RUN_TESTS, DEPLOY)

### GitHub Actions Configuration

Secrets to configure in GitHub repository:

```yaml
AWS_ACCESS_KEY_ID: <your-access-key>
AWS_SECRET_ACCESS_KEY: <your-secret-key>
AWS_ACCOUNT_ID: <12-digit-account-id>
SSH_PRIVATE_KEY: <contents of ~/.ssh/microservices-cicd>
JWT_SECRET: <generated-secret>
```

## Verification

### 1. Check Infrastructure

```bash
cd infrastructure/terraform/environments/dev

# Verify all resources created
terraform show

# Get output values
terraform output
```

### 2. Verify Server Connectivity

```bash
cd ansible

# Ping all servers
ansible all -i inventory/hosts.ini -m ping

# Check Docker status
ansible microservices -i inventory/hosts.ini -m command -a "docker ps"
```

### 3. Test Services

Get Load Balancer DNS:

```bash
cd infrastructure/terraform/environments/dev
LB_DNS=$(terraform output -raw load_balancer_dns)
```

Test endpoints:

```bash
# API Gateway health
curl http://$LB_DNS/health

# All services health
curl http://$LB_DNS/health/services

# Test authentication
curl -X POST http://$LB_DNS/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Test products
curl http://$LB_DNS/api/products/products

# Test orders (requires auth token)
curl http://$LB_DNS/api/orders/orders
```

### 4. Monitor Logs

SSH into a microservices server:

```bash
ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>

# View Docker logs
docker-compose -f /opt/microservices/docker-compose.yml logs -f

# View specific service
docker logs api-gateway -f
```

## Troubleshooting

### Terraform Issues

**State lock error**:
```bash
terraform force-unlock <lock-id>
```

**Resource already exists**:
```bash
terraform import <resource-type>.<name> <resource-id>
```

### Ansible Issues

**SSH connection failed**:
```bash
# Test SSH manually
ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>

# Verify inventory
ansible-inventory -i inventory/hosts.ini --list
```

**Permission denied**:
```bash
chmod 600 ~/.ssh/microservices-cicd
```

### Docker Issues

**Image pull failed**:
```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

**Container won't start**:
```bash
# Check logs
docker logs <container-name>

# Check health
docker inspect <container-name> | grep Health
```

### Service Health Issues

**Service returns 503**:
- Check if all containers are running: `docker ps`
- View container logs: `docker logs <container>`
- Verify network connectivity: `docker network inspect microservices-network`

**Load Balancer returns 502/504**:
- Check target group health
- Verify security group rules
- Check service health endpoints directly

## Cleanup

To destroy all resources:

```bash
# Stop services
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags stop

# Destroy infrastructure
cd ../infrastructure/terraform/environments/dev
terraform destroy

# Delete ECR repositories (optional)
aws ecr delete-repository --repository-name microservices-cicd-dev-api-gateway --force
aws ecr delete-repository --repository-name microservices-cicd-dev-auth-service --force
aws ecr delete-repository --repository-name microservices-cicd-dev-product-service --force
aws ecr delete-repository --repository-name microservices-cicd-dev-order-service --force
```

## Next Steps

- [Testing Guide](TESTING.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [CI/CD Workflows](CICD.md)
- [Monitoring and Logging](MONITORING.md)
