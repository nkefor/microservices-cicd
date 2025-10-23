# Quick Start Guide

Get the microservices CI/CD project up and running in minutes!

## Prerequisites Check

Before starting, ensure you have:

- [ ] AWS account with billing enabled
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.5.0
- [ ] Ansible >= 2.14
- [ ] Docker >= 24.0
- [ ] Node.js >= 18.x
- [ ] Python >= 3.11
- [ ] Git

## 5-Minute Local Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd microservices-cicd
```

### 2. Install Dependencies

```bash
# Node.js services
cd services/api-gateway && npm install && cd ../..
cd services/product-service && npm install && cd ../..

# Python services
cd services/auth-service && pip install -r requirements.txt && cd ../..
cd services/order-service && pip install -r requirements.txt && cd ../..
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env and set JWT_SECRET
```

### 4. Start Services Locally

```bash
docker-compose up -d
```

### 5. Test

```bash
# Wait for services to start
sleep 20

# Test API Gateway
curl http://localhost:3000/health

# Test all services
curl http://localhost:3000/health/services

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Get products
curl http://localhost:3000/api/products/products
```

**Success!** All services are running locally.

Stop services:
```bash
docker-compose down
```

---

## AWS Deployment (15 Minutes)

### Option 1: Automated Setup

```bash
# Run the setup script
./scripts/setup.sh

# Deploy to AWS
./scripts/deploy.sh dev
```

That's it! The scripts will:
- Configure AWS credentials
- Generate SSH keys
- Create ECR repositories
- Deploy infrastructure
- Provision servers
- Deploy applications
- Run health checks

### Option 2: Manual Deployment

#### Step 1: Configure AWS (2 min)

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: us-east-1
# Output format: json
```

#### Step 2: Generate SSH Key (1 min)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/microservices-cicd
```

#### Step 3: Create ECR Repositories (2 min)

```bash
for service in api-gateway auth-service product-service order-service; do
  aws ecr create-repository \
    --repository-name microservices-cicd-dev-$service \
    --image-scanning-configuration scanOnPush=true
done
```

#### Step 4: Configure Terraform (3 min)

```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
- Set `ssh_public_key` (content of `~/.ssh/microservices-cicd.pub`)
- Set `allowed_ssh_cidr` (your IP with /32)

```bash
# Get your IP
curl https://checkip.amazonaws.com
```

#### Step 5: Deploy Infrastructure (5 min)

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

Save outputs:
```bash
terraform output
```

#### Step 6: Wait for EC2 Instances (2 min)

```bash
sleep 120
```

#### Step 7: Deploy Application (5 min)

```bash
cd ../../../../ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

#### Step 8: Verify Deployment (1 min)

```bash
# Get Load Balancer DNS
cd ../infrastructure/terraform/environments/dev
LB_DNS=$(terraform output -raw load_balancer_dns)

# Test
curl http://$LB_DNS/health
curl http://$LB_DNS/health/services
```

**Success!** Your microservices are running on AWS.

---

## Access Your Deployment

### API Gateway
```bash
LB_DNS=$(cd infrastructure/terraform/environments/dev && terraform output -raw load_balancer_dns)
echo "API Gateway: http://$LB_DNS"
```

### Jenkins
```bash
JENKINS_IP=$(cd infrastructure/terraform/environments/dev && terraform output -raw jenkins_public_ip)
echo "Jenkins: http://$JENKINS_IP:8080"

# Get initial password
ssh -i ~/.ssh/microservices-cicd ubuntu@$JENKINS_IP \
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### SSH to Servers
```bash
# Get IPs
cd infrastructure/terraform/environments/dev
terraform output

# Connect
ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>
```

---

## Testing the Deployment

### 1. Health Checks

```bash
LB_DNS=$(cd infrastructure/terraform/environments/dev && terraform output -raw load_balancer_dns)

# API Gateway
curl http://$LB_DNS/health

# All services
curl http://$LB_DNS/health/services
```

### 2. Authentication

```bash
# Login
curl -X POST http://$LB_DNS/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq

# Save token
TOKEN=$(curl -s -X POST http://$LB_DNS/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r .token)

# Get profile
curl -H "Authorization: Bearer $TOKEN" \
  http://$LB_DNS/api/auth/profile | jq
```

### 3. Products

```bash
# List products
curl http://$LB_DNS/api/products/products | jq

# Get specific product
PRODUCT_ID=$(curl -s http://$LB_DNS/api/products/products | jq -r .products[0].id)
curl http://$LB_DNS/api/products/products/$PRODUCT_ID | jq

# Create product
curl -X POST http://$LB_DNS/api/products/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "stock": 10,
    "category": "Test"
  }' | jq
```

### 4. Orders

```bash
# Create order
curl -X POST http://$LB_DNS/api/orders/orders \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"test-user\",
    \"items\": [{
      \"productId\": \"$PRODUCT_ID\",
      \"quantity\": 1
    }]
  }" | jq

# Get order stats
curl http://$LB_DNS/api/orders/stats | jq
```

---

## CI/CD Setup

### Jenkins

1. Access Jenkins at `http://<jenkins-ip>:8080`
2. Use initial admin password (see above)
3. Install suggested plugins
4. Create admin user
5. Create pipeline job:
   - New Item → Pipeline
   - GitHub project URL
   - Pipeline script from SCM
   - Repository URL
   - Script path: `Jenkinsfile`

### GitHub Actions

Add these secrets to your GitHub repository:

```
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
AWS_ACCOUNT_ID=<12-digit-account-id>
SSH_PRIVATE_KEY=<content of ~/.ssh/microservices-cicd>
JWT_SECRET=<generated-secret>
```

Push to trigger workflow:
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

---

## Monitoring

### View Logs

```bash
# SSH to server
ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>

# View all service logs
cd /opt/microservices
docker-compose logs -f

# View specific service
docker logs api-gateway -f

# View health check logs
tail -f /opt/microservices/logs/health-check.log
```

### CloudWatch

Access CloudWatch Logs in AWS Console:
- Log Group: `/microservices/dev`
- Streams per instance for application logs

---

## Cleanup

### Stop Services (Keep Infrastructure)

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags stop
```

### Destroy Everything

```bash
# Destroy infrastructure
cd infrastructure/terraform/environments/dev
terraform destroy -auto-approve

# Delete ECR repositories (optional)
for service in api-gateway auth-service product-service order-service; do
  aws ecr delete-repository \
    --repository-name microservices-cicd-dev-$service \
    --force
done
```

---

## Troubleshooting

### Services not responding
```bash
# Check Docker status
ssh -i ~/.ssh/microservices-cicd ubuntu@<server-ip>
docker ps
docker-compose logs
```

### Terraform errors
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check Terraform state
cd infrastructure/terraform/environments/dev
terraform show
```

### Ansible connection issues
```bash
# Test connectivity
cd ansible
ansible all -i inventory/hosts.ini -m ping

# Verify SSH key
chmod 600 ~/.ssh/microservices-cicd
```

---

## Next Steps

- [ ] Review [Architecture Documentation](docs/ARCHITECTURE.md)
- [ ] Explore [API Documentation](docs/API.md)
- [ ] Set up monitoring dashboards
- [ ] Configure staging environment
- [ ] Implement database layer
- [ ] Add automated tests
- [ ] Set up SSL/TLS certificates

---

## Getting Help

- Review [Deployment Guide](docs/DEPLOYMENT.md) for detailed steps
- Check [Architecture docs](docs/ARCHITECTURE.md) for system design
- See [API docs](docs/API.md) for endpoint details
- Open GitHub issue for problems

---

## Success Checklist

- [ ] Services running locally with Docker Compose
- [ ] Infrastructure deployed on AWS
- [ ] Load Balancer health checks passing
- [ ] All services responding to API calls
- [ ] Authentication working
- [ ] Jenkins accessible
- [ ] CI/CD pipeline configured

**Congratulations!** You've successfully deployed a production-grade microservices architecture with automated CI/CD!
