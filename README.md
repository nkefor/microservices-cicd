# Microservices CI/CD Infrastructure

A comprehensive microservices architecture with automated CI/CD pipelines on AWS.

## Architecture Overview

This project implements a production-ready microservices architecture with:

- **Container Orchestration**: ECS Fargate / EKS (Kubernetes)
- **API Gateway**: Centralized API management and routing
- **Service Mesh**: Service-to-service communication
- **CI/CD**: Automated deployment pipelines with GitHub Actions
- **Monitoring**: CloudWatch, X-Ray, and custom metrics
- **Infrastructure as Code**: Terraform for all AWS resources

## Project Structure

```
microservices-cicd/
├── infrastructure/           # Infrastructure as Code
│   ├── terraform/           # Terraform configurations
│   │   ├── modules/        # Reusable Terraform modules
│   │   │   ├── vpc/       # VPC with public/private subnets
│   │   │   ├── ecs/       # ECS cluster and services
│   │   │   ├── eks/       # EKS cluster configuration
│   │   │   ├── ecr/       # Container registry
│   │   │   ├── rds/       # PostgreSQL database
│   │   │   ├── elasticache/ # Redis cache
│   │   │   └── monitoring/  # CloudWatch, X-Ray setup
│   │   └── environments/   # Environment-specific configs
│   │       ├── dev/
│   │       ├── staging/
│   │       └── prod/
│   └── kubernetes/         # K8s manifests (if using EKS)
│
├── services/               # Microservices
│   ├── api-gateway/       # API Gateway service
│   ├── auth-service/      # Authentication & authorization
│   ├── product-service/   # Product management
│   └── order-service/     # Order processing
│
├── cicd/                  # CI/CD configurations
│   ├── github-actions/    # GitHub Actions workflows
│   └── buildspec/        # AWS CodeBuild specs
│
├── scripts/              # Utility scripts
└── docs/                 # Documentation

```

## Services

### API Gateway
- Routes requests to appropriate microservices
- Handles authentication and rate limiting
- Provides unified API endpoint

### Auth Service
- User authentication and authorization
- JWT token management
- OAuth 2.0 integration

### Product Service
- Product catalog management
- Inventory tracking
- Search and filtering

### Order Service
- Order processing and management
- Payment integration
- Order status tracking

## Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** v1.5+
- **Docker** and Docker Compose
- **kubectl** (if using EKS)
- **Node.js** v18+ or **Python** 3.11+
- **Git**

## Quick Start

### 1. Clone and Setup

```bash
cd microservices-cicd
cp infrastructure/terraform/terraform.tfvars.example infrastructure/terraform/terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Deploy Infrastructure

```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 3. Build and Push Docker Images

```bash
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push services
./scripts/build-and-push.sh
```

### 4. Deploy Services

```bash
# ECS deployment
./scripts/deploy-ecs.sh dev

# Or for EKS
kubectl apply -f infrastructure/kubernetes/
```

## Development Workflow

### Local Development

```bash
# Start all services locally with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Adding a New Service

1. Create service directory under `services/`
2. Add Dockerfile and application code
3. Update Terraform ECS/EKS module
4. Add GitHub Actions workflow
5. Deploy

### CI/CD Pipeline

The CI/CD pipeline automatically:
1. Runs tests on every PR
2. Builds Docker images
3. Pushes to ECR
4. Deploys to dev environment
5. Requires approval for staging/prod
6. Performs health checks
7. Rolls back on failure

## Infrastructure Components

### Networking
- Multi-AZ VPC with public and private subnets
- NAT Gateways for outbound internet access
- Security groups with least privilege access
- VPC endpoints for AWS services

### Compute
- ECS Fargate for serverless containers
- Auto-scaling based on CPU/memory metrics
- Application Load Balancer with health checks

### Storage
- RDS PostgreSQL with Multi-AZ
- ElastiCache Redis for caching
- S3 for static assets and backups

### Security
- Secrets Manager for sensitive data
- IAM roles with least privilege
- TLS/SSL encryption in transit
- Encryption at rest for all data stores

### Monitoring
- CloudWatch Logs and Metrics
- X-Ray distributed tracing
- Custom application metrics
- CloudWatch Alarms for critical metrics

## Environment Variables

Each service requires specific environment variables. See individual service READMEs for details.

Common variables:
- `AWS_REGION`: AWS region (default: us-east-1)
- `ENVIRONMENT`: Environment name (dev/staging/prod)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: Secret for JWT signing

## Security Considerations

- All credentials stored in AWS Secrets Manager
- No hardcoded secrets in code or configuration
- Least privilege IAM policies
- Security groups restrict traffic to necessary ports
- Regular security patches and updates
- Audit logging enabled

## Monitoring and Debugging

### View Logs
```bash
# CloudWatch Logs
aws logs tail /ecs/service-name --follow

# ECS task logs
aws ecs describe-tasks --cluster cluster-name --tasks task-id
```

### Trace Requests
```bash
# X-Ray traces
aws xray get-trace-summaries --start-time $(date -u -d '5 minutes ago' +%s) --end-time $(date +%s)
```

### Metrics
Access CloudWatch dashboard at: https://console.aws.amazon.com/cloudwatch/

## Cost Optimization

- Use Fargate Spot for non-critical workloads
- Enable auto-scaling to match demand
- Use reserved instances for databases
- Implement caching to reduce database load
- Review and clean up unused resources

## Troubleshooting

### Common Issues

**Terraform State Lock**
```bash
terraform force-unlock <lock-id>
```

**ECS Task Failing to Start**
```bash
aws ecs describe-tasks --cluster <cluster> --tasks <task-id>
aws logs tail /ecs/<service> --follow
```

**Docker Image Pull Errors**
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
```

## Contributing

1. Create a feature branch
2. Make changes and test locally
3. Submit PR with description
4. Wait for CI checks to pass
5. Request review

## License

MIT License

## Support

For issues and questions, please open a GitHub issue.
