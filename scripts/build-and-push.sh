#!/bin/bash

# Build and push Docker images to ECR
# Usage: ./scripts/build-and-push.sh [image_tag]

set -e

IMAGE_TAG=${1:-latest}
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

SERVICES=("api-gateway" "auth-service" "product-service" "order-service")

echo "========================================="
echo "Building and Pushing Docker Images"
echo "========================================="
echo "Image Tag: $IMAGE_TAG"
echo "ECR Registry: $ECR_REGISTRY"
echo "========================================="

# Login to ECR
echo ""
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push each service
for service in "${SERVICES[@]}"; do
    echo ""
    echo "========================================="
    echo "Building $service..."
    echo "========================================="

    cd "$PROJECT_ROOT/services/$service"

    # Build image
    docker build \
        -t "$ECR_REGISTRY/$service:$IMAGE_TAG" \
        -t "$ECR_REGISTRY/$service:latest" \
        .

    echo ""
    echo "Pushing $service to ECR..."
    docker push "$ECR_REGISTRY/$service:$IMAGE_TAG"
    docker push "$ECR_REGISTRY/$service:latest"

    echo "✓ $service pushed successfully"
done

echo ""
echo "========================================="
echo "All images built and pushed successfully!"
echo "========================================="
echo ""
echo "Images:"
for service in "${SERVICES[@]}"; do
    echo "  $ECR_REGISTRY/$service:$IMAGE_TAG"
done
echo ""
