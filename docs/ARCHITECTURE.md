# Architecture Documentation

## Overview

This project implements a production-grade microservices architecture on AWS with automated CI/CD pipelines. The system demonstrates modern DevOps practices including Infrastructure as Code, containerization, automated testing, and continuous deployment.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                ┌────────▼─────────┐
                │  Application     │
                │  Load Balancer   │
                └────────┬─────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
   │ Server 1 │    │ Server 2 │    │ Server 3 │
   │          │    │          │    │          │
   │ Docker   │    │ Docker   │    │ Docker   │
   │ Compose  │    │ Compose  │    │ Compose  │
   └──────────┘    └──────────┘    └──────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │   Microservices Network         │
        │                                  │
        │  ┌──────────────────────────┐  │
        │  │    API Gateway :3000     │  │
        │  └────────┬─────────────────┘  │
        │           │                     │
        │  ┌────────┼──────────┬──────┐  │
        │  │        │          │      │  │
        │  │  ┌─────▼───┐ ┌───▼────┐ │  │
        │  │  │ Auth    │ │Product │ │  │
        │  │  │ :3001   │ │ :3002  │ │  │
        │  │  └─────────┘ └───┬────┘ │  │
        │  │                  │      │  │
        │  │            ┌─────▼────┐ │  │
        │  │            │  Order   │ │  │
        │  │            │  :3003   │ │  │
        │  │            └──────────┘ │  │
        │  └─────────────────────────┘  │
        └─────────────────────────────────┘
```

## Infrastructure Components

### 1. Networking

#### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Subnets**:
  - Public subnets (2 AZs): For Load Balancer and NAT Gateways
  - Private subnets (2 AZs): For application servers (future)
- **Internet Gateway**: Public internet access
- **NAT Gateways**: Outbound internet for private subnets
- **Route Tables**: Separate for public and private subnets

#### Security Groups

**Microservices Security Group**:
- SSH (22): Limited to specified CIDR
- HTTP (80): Public access
- HTTPS (443): Public access
- API Gateway (3000): Public access
- Internal ports (3001-3004): VPC only
- All traffic within security group

**Jenkins Security Group**:
- SSH (22): Limited to specified CIDR
- Jenkins (8080): Limited to specified CIDR
- Outbound: All traffic

### 2. Compute Resources

#### EC2 Instances

**Jenkins Server**:
- Instance Type: t3.medium (2 vCPU, 4GB RAM)
- OS: Ubuntu 22.04 LTS
- Purpose: CI/CD orchestration
- Components:
  - Jenkins
  - Docker
  - Ansible
  - AWS CLI

**Microservices Servers** (3 instances):
- Instance Type: t3.small (2 vCPU, 2GB RAM)
- OS: Ubuntu 22.04 LTS
- Purpose: Host containerized microservices
- Components:
  - Docker Engine
  - Docker Compose
  - CloudWatch Agent
  - Application containers

### 3. Load Balancing

**Application Load Balancer**:
- Type: Application (Layer 7)
- Scheme: Internet-facing
- Listeners: HTTP (80)
- Target Group: API Gateway on port 3000
- Health Checks:
  - Path: /health
  - Interval: 30s
  - Timeout: 5s
  - Healthy threshold: 2
  - Unhealthy threshold: 2

### 4. Container Registry

**Amazon ECR**:
- Repositories per service:
  - api-gateway
  - auth-service
  - product-service
  - order-service
- Image scanning: Enabled
- Encryption: AES256
- Lifecycle policy: Keep last 30 images, remove untagged after 7 days

## Application Architecture

### Microservices

#### 1. API Gateway (Node.js/Express)
**Port**: 3000
**Responsibilities**:
- Request routing to backend services
- Rate limiting
- CORS handling
- Security headers (Helmet)
- Request/response logging
- Service health aggregation

**Dependencies**:
- express
- axios
- cors
- helmet
- morgan
- express-rate-limit

#### 2. Auth Service (Python/Flask)
**Port**: 3001
**Responsibilities**:
- User authentication
- JWT token generation and validation
- User registration
- Password hashing (bcrypt)
- Role-based access control

**Dependencies**:
- Flask
- PyJWT
- bcrypt
- gunicorn (production server)

**Endpoints**:
- POST /register - User registration
- POST /login - Authentication
- POST /validate - Token validation
- GET /profile - User profile (authenticated)
- GET /users - List users (admin only)

#### 3. Product Service (Node.js/Express)
**Port**: 3002
**Responsibilities**:
- Product catalog management
- Inventory tracking
- Product search and filtering
- CRUD operations for products

**Endpoints**:
- GET /products - List all products
- GET /products/:id - Get product details
- POST /products - Create product
- PUT /products/:id - Update product
- DELETE /products/:id - Delete product
- POST /products/:id/check-availability - Check stock

#### 4. Order Service (Python/Flask)
**Port**: 3003
**Responsibilities**:
- Order creation and management
- Integration with Product Service
- Order status tracking
- Payment processing integration
- Order statistics

**Dependencies**:
- Product Service (for availability checks)

**Endpoints**:
- GET /orders - List orders
- GET /orders/:id - Get order details
- POST /orders - Create order
- PUT /orders/:id - Update order status
- DELETE /orders/:id - Cancel order
- GET /orders/stats - Order statistics

## CI/CD Architecture

### Jenkins Pipeline

**Stages**:
1. **Checkout**: Clone repository
2. **Install Dependencies**: Parallel installation for Node.js and Python
3. **Run Tests**: Execute unit tests for all services
4. **Build Docker Images**: Parallel builds
5. **Push to ECR**: Upload images with tags
6. **Deploy with Ansible**: Provision and deploy
7. **Health Check**: Verify deployment

**Environment Variables**:
- AWS_REGION
- ECR_REGISTRY
- IMAGE_TAG
- ENVIRONMENT

### GitHub Actions Workflow

**Jobs**:
1. **Test**: Run tests for all services (matrix build)
2. **Build and Push**: Build Docker images and push to ECR
3. **Deploy**: Deploy using Ansible with environment approval

**Triggers**:
- Push to main/develop branches
- Pull requests
- Manual workflow dispatch

## Data Flow

### Request Flow

1. **Client Request** → Load Balancer
2. **Load Balancer** → API Gateway (port 3000)
3. **API Gateway** routes to:
   - Auth Service for authentication
   - Product Service for products
   - Order Service for orders
4. **Services** process and return responses
5. **API Gateway** → Load Balancer → Client

### Order Creation Flow

1. Client → API Gateway → Order Service
2. Order Service → Product Service (check availability)
3. Product Service validates stock
4. Order Service creates order
5. Response chain: Order → API Gateway → Client

## Deployment Architecture

### Infrastructure as Code

**Terraform** manages:
- VPC and networking
- EC2 instances
- Security groups
- Load balancers
- IAM roles

**Ansible** manages:
- Server configuration
- Package installation
- Docker setup
- Application deployment
- Service orchestration

### Container Orchestration

**Docker Compose** configuration:
- Service definitions
- Networking
- Environment variables
- Health checks
- Logging configuration
- Resource limits

## Monitoring and Logging

### CloudWatch Integration

**Metrics Collected**:
- CPU utilization
- Memory usage
- Disk usage
- Network I/O
- Container metrics
- Custom application metrics

**Log Groups**:
- /microservices/{environment}/application
- /microservices/{environment}/syslog
- Container logs

### Health Monitoring

**Health Check Endpoints**:
- Individual service health: /{service}/health
- Aggregate health: /health/services

**Automated Checks**:
- Cron-based health checks every 5 minutes
- Load Balancer target health
- Container health checks

## Security Architecture

### Network Security

- Security groups with least privilege
- Private subnets for sensitive resources
- NAT Gateways for outbound traffic
- No direct internet access to application servers

### Application Security

- JWT-based authentication
- Password hashing with bcrypt
- Rate limiting on API Gateway
- CORS configuration
- Security headers (Helmet)
- Container user isolation

### Secrets Management

- Environment variables for configuration
- AWS Secrets Manager for sensitive data
- No hardcoded credentials
- SSH key-based authentication

## Scalability Considerations

### Current Architecture
- Horizontal scaling via additional EC2 instances
- Load balancer distribution
- Stateless services

### Future Enhancements
- Auto-scaling groups
- Container orchestration (ECS/EKS)
- Database layer (RDS)
- Caching layer (ElastiCache)
- CDN for static assets
- Multi-region deployment

## High Availability

**Current**:
- Multi-AZ deployment
- Load balancer health checks
- Automated recovery via systemd

**Planned**:
- Auto-scaling based on metrics
- Cross-region replication
- Database failover
- Backup and disaster recovery

## Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| Infrastructure | AWS, Terraform |
| Configuration | Ansible |
| Containers | Docker, Docker Compose |
| CI/CD | Jenkins, GitHub Actions |
| Load Balancing | AWS Application Load Balancer |
| Monitoring | CloudWatch, Custom metrics |
| Node.js Services | Express, Axios |
| Python Services | Flask, Gunicorn |
| Security | JWT, bcrypt, Helmet |
| Version Control | Git, GitHub |

## Design Principles

1. **Infrastructure as Code**: All infrastructure defined in version-controlled code
2. **Immutable Infrastructure**: Container images built once, deployed everywhere
3. **Automation**: Minimal manual intervention
4. **Observability**: Comprehensive logging and monitoring
5. **Security**: Defense in depth, least privilege
6. **Scalability**: Designed for horizontal scaling
7. **Resilience**: Health checks and automated recovery
