#!/bin/bash
set -euo pipefail

# Deploy Groq Bot to EKS
echo "🚀 Deploying Groq Bot to EKS..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl not configured. Run: aws eks update-kubeconfig --region us-east-1 --name groq-bot-eks-cluster"
    exit 1
fi

# Check if secret exists
if ! kubectl get secret groq-bot-secret -n groq-bot &> /dev/null; then
    echo "❌ Secret not found. Create it with:"
    echo "kubectl create secret generic groq-bot-secret -n groq-bot --from-literal=OPENAI_API_KEY='your-groq-key'"
    exit 1
fi

# Deploy application
kubectl apply -f k8s/groq-bot-deployment.yaml
kubectl apply -f k8s/groq-bot-ingress.yaml

# Wait for rollout
kubectl rollout status deployment/groq-bot -n groq-bot --timeout=300s

echo "✅ Deployment complete!"
echo "🌐 Application available at: https://clone.reborncloud.online"
