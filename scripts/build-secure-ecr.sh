#!/bin/bash
set -euo pipefail

# Configuration
REGION="us-east-1"
ACCOUNT_ID="739275449845"
ECR_REPO="openai-gptbotclone"
SECRET_NAME="openai-gptbotclone"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"

# Get git hash for tagging
GIT_HASH=$(git rev-parse --short HEAD)
IMAGE_TAG="v1.0.0-${GIT_HASH}"

echo "🔐 Retrieving OpenAI API key from AWS Secrets Manager..."
OPENAI_API_KEY=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text | jq -r '.OPENAI_API_KEY')

echo "🔑 Logging into ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "🏗️ Building multi-arch image with secrets..."
docker buildx create --name ecr-builder --use --bootstrap 2>/dev/null || docker buildx use ecr-builder

# Build with secret as build arg (not stored in layers)
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --file Dockerfile.simple \
    --secret id=openai_key,env=OPENAI_API_KEY \
    --tag "${ECR_URI}:${IMAGE_TAG}" \
    --tag "${ECR_URI}:latest" \
    --push \
    .

echo "✅ Image pushed to ECR: ${ECR_URI}:${IMAGE_TAG}"
echo "📋 Update your K8s deployment with: ${ECR_URI}:${IMAGE_TAG}"
