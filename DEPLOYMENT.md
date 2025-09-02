# 🚀 Deployment Guide - Reborncloud Groq Bot

## Current Production Deployment

### 🌐 Live Environment
- **URL**: https://clone.reborncloud.online
- **Status**: ✅ Active
- **Last Deployed**: September 2, 2025
- **Version**: v1.1.1

### 📊 Infrastructure Status
```
EKS Cluster: groq-bot-eks-cluster (us-east-1)
├── Nodes: 2x t3.medium (auto-scaling 1-4)
├── Pods: 3 replicas (groq-bot namespace)
├── Load Balancer: groq-bot-lb (ALB)
├── ECR Repository: groq-bot-clone
└── SSL Certificate: ACM managed
```

## 🔧 Quick Commands

### Check Application Status
```bash
# Switch to correct cluster
kubectl config use-context elson@groq-bot-eks-cluster.us-east-1.eksctl.io

# Check pods
kubectl get pods -n groq-bot

# View logs
kubectl logs -f deployment/groq-bot -n groq-bot

# Check ingress
kubectl get ingress -n groq-bot
```

### Update Deployment
```bash
# Build new image
docker buildx build --platform linux/amd64,linux/arm64 \
  --tag 739275449845.dkr.ecr.us-east-1.amazonaws.com/groq-bot-clone:v1.1.2 \
  --push .

# Update deployment
kubectl set image deployment/groq-bot \
  groq-bot=739275449845.dkr.ecr.us-east-1.amazonaws.com/groq-bot-clone:v1.1.2 \
  -n groq-bot

# Wait for rollout
kubectl rollout status deployment/groq-bot -n groq-bot
```

### Test Endpoints
```bash
# Test models API
curl -X POST https://clone.reborncloud.online/api/models \
  -H "Content-Type: application/json" -d '{}'

# Test chat API
curl -X POST https://clone.reborncloud.online/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": {"id": "llama-3.1-8b-instant", "name": "Llama 3.1 8B", "maxLength": 120000, "tokenLimit": 131072},
    "messages": [{"role": "user", "content": "Hello"}],
    "key": "",
    "prompt": "You are a helpful AI assistant."
  }'
```

## 🔐 Secrets Management

### Current Secrets
```bash
# View secret (base64 encoded)
kubectl get secret groq-bot-secret -n groq-bot -o yaml

# Update Groq API key
kubectl create secret generic groq-bot-secret -n groq-bot \
  --from-literal=OPENAI_API_KEY="your-new-groq-key" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### AWS Secrets Manager
```bash
# Update in AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id openai-gptbotclone \
  --secret-string '{"OPENAI_API_KEY":"your-new-groq-key"}' \
  --region us-east-1
```

## 🔄 Rollback Procedures

### Quick Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/groq-bot -n groq-bot

# Check rollout status
kubectl rollout status deployment/groq-bot -n groq-bot

# View rollout history
kubectl rollout history deployment/groq-bot -n groq-bot
```

### Emergency Procedures
```bash
# Scale down (maintenance mode)
kubectl scale deployment groq-bot --replicas=0 -n groq-bot

# Scale up
kubectl scale deployment groq-bot --replicas=3 -n groq-bot

# Force restart all pods
kubectl rollout restart deployment/groq-bot -n groq-bot
```

## 📈 Monitoring

### Health Checks
```bash
# Check pod health
kubectl describe pods -l app=groq-bot -n groq-bot

# Check service endpoints
kubectl get endpoints -n groq-bot

# Check ingress status
kubectl describe ingress groq-bot-lb -n groq-bot
```

### Performance Metrics
```bash
# Resource usage
kubectl top pods -n groq-bot

# Node resource usage
kubectl top nodes

# Check HPA (if configured)
kubectl get hpa -n groq-bot
```

## 🚨 Troubleshooting

### Common Issues

#### 1. 502 Bad Gateway
```bash
# Check pod status
kubectl get pods -n groq-bot

# Check pod logs
kubectl logs -l app=groq-bot -n groq-bot --tail=50

# Check service
kubectl describe service groq-bot-service -n groq-bot
```

#### 2. SSL Certificate Issues
```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:739275449845:certificate/852b8fe6-1f95-451f-b450-179629fc8e8e \
  --region us-east-1
```

#### 3. DNS Resolution
```bash
# Check Route53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id Z01988762X8VUJLMH2T1Q \
  --query 'ResourceRecordSets[?Name==`clone.reborncloud.online.`]'
```

#### 4. API Key Issues
```bash
# Test Groq API directly
curl -H "Authorization: Bearer YOUR_GROQ_KEY" \
  https://api.groq.com/openai/v1/models
```

## 🔧 Configuration Files

### Key Kubernetes Manifests
- `k8s/groq-bot-deployment.yaml` - Main application deployment
- `k8s/groq-bot-ingress.yaml` - ALB ingress configuration

### Environment Variables
```yaml
env:
- name: OPENAI_API_KEY
  valueFrom:
    secretKeyRef:
      name: groq-bot-secret
      key: OPENAI_API_KEY
- name: OPENAI_API_HOST
  value: "https://api.groq.com/openai"
- name: DEFAULT_MODEL
  value: "llama-3.1-8b-instant"
- name: NODE_ENV
  value: "production"
```

## 📞 Emergency Contacts

- **Primary**: Reborncloud DevOps Team
- **Backup**: AWS Support (if infrastructure issues)
- **Groq Support**: For API-related issues

---

**Last Updated**: September 2, 2025  
**Maintainer**: Reborncloud Team
