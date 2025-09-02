#!/bin/bash
set -euo pipefail

REGION="us-east-1"
DOMAIN="clone.reborncloud.online"
CERT_ARN="arn:aws:acm:us-east-1:739275449845:certificate/852b8fe6-1f95-451f-b450-179629fc8e8e"

echo "🚀 Deploying ChatGPT clone with secure domain access..."

# Deploy application
echo "📦 Deploying application to EKS..."
kubectl apply -f k8s/ecr-deployment.yaml
kubectl apply -f k8s/alb-ingress.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/chatbot-ui -n chatbot-ui --timeout=300s

# Wait for ALB to be provisioned
echo "🔧 Waiting for ALB to be provisioned..."
sleep 60

# Get ALB hostname
ALB_HOSTNAME=$(kubectl get ingress chatbot-ui-ingress -n chatbot-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 ALB Hostname: $ALB_HOSTNAME"

# Create Route53 A record pointing to ALB
echo "📡 Creating Route53 A record..."
aws route53 change-resource-record-sets \
    --hosted-zone-id Z01988762X8VUJLMH2T1Q \
    --change-batch "{
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$DOMAIN\",
                \"Type\": \"A\",
                \"AliasTarget\": {
                    \"DNSName\": \"$ALB_HOSTNAME\",
                    \"EvaluateTargetHealth\": false,
                    \"HostedZoneId\": \"Z35SXDOTRQ7X7K\"
                }
            }
        }]
    }"

echo "⏳ Waiting for DNS propagation..."
sleep 60

# Verify domain access
echo "🔍 Verifying domain access..."
for i in {1..10}; do
    if curl -f -s -I "https://$DOMAIN" | grep -q "200 OK"; then
        echo "✅ Domain is accessible: https://$DOMAIN"
        break
    fi
    echo "Attempt $i/10 failed, retrying in 30s..."
    sleep 30
done

echo "🎉 Deployment complete! ChatGPT clone is accessible at: https://$DOMAIN"
