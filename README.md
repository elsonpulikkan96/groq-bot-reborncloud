# 🤖 Reborncloud Groq Bot

A production-ready ChatGPT clone powered by Groq's free API, deployed on AWS EKS with enterprise-grade infrastructure.

## 🌐 Live Demo
**URL**: https://clone.reborncloud.online

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Route53 DNS   │───▶│  Application     │───▶│   EKS Cluster   │
│                 │    │  Load Balancer   │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                          │
                              ▼                          ▼
                       ┌──────────────┐         ┌──────────────┐
                       │  SSL/TLS     │         │  Groq API    │
                       │  Certificate │         │  Integration │
                       └──────────────┘         └──────────────┘
```

## 🚀 Technologies Stack

### Frontend
- **Framework**: Next.js 13+ (React 18)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: Custom React components
- **State Management**: React Hooks + Context
- **Internationalization**: next-i18next

### Backend
- **Runtime**: Node.js 18 (Alpine Linux)
- **API Framework**: Next.js API Routes (Edge Runtime)
- **AI Provider**: Groq API (Free Tier)
- **Streaming**: Server-Sent Events (SSE)
- **Token Management**: tiktoken for token counting

### Infrastructure (AWS)
- **Container Registry**: Amazon ECR
- **Orchestration**: Amazon EKS (Kubernetes 1.32)
- **Load Balancer**: Application Load Balancer (ALB)
- **DNS**: Route53
- **SSL/TLS**: AWS Certificate Manager (ACM)
- **Secrets**: AWS Secrets Manager
- **Networking**: VPC with public/private subnets
- **Compute**: EC2 instances (t3.medium)

## 🤖 AI Models Available

| Model | Provider | Speed | Context Window | Use Case |
|-------|----------|-------|----------------|----------|
| `llama-3.1-8b-instant` | Meta | ⚡ Fast | 131K tokens | General chat |
| `llama-3.3-70b-versatile` | Meta | 🧠 Powerful | 131K tokens | Complex tasks |
| `gemma2-9b-it` | Google | ⚖️ Balanced | 8K tokens | Instruction following |
| `compound-beta` | Groq | 🔬 Experimental | 131K tokens | Latest features |

## 📁 Project Structure

```
groq-bot-reborncloud/
├── components/           # React UI components
│   ├── Chat/            # Chat interface
│   ├── Chatbar/         # Sidebar with conversations
│   ├── Promptbar/       # Prompt management
│   └── Mobile/          # Mobile-specific components
├── pages/               # Next.js pages and API routes
│   ├── api/             # Backend API endpoints
│   │   ├── chat.ts      # Chat completion endpoint
│   │   └── models.ts    # Available models endpoint
│   ├── _app.tsx         # App configuration
│   └── index.tsx        # Main chat interface
├── types/               # TypeScript type definitions
├── utils/               # Utility functions
├── k8s/                 # Kubernetes manifests
├── scripts/             # Deployment scripts
└── public/              # Static assets
```

## 🔧 Key Features

### 🎯 Core Functionality
- **Real-time Chat**: Streaming responses with typing indicators
- **Multiple Models**: Switch between different AI models
- **Conversation Management**: Save, load, and organize chats
- **Prompt Templates**: Pre-built and custom prompts
- **Export/Import**: Backup conversations in multiple formats
- **Mobile Responsive**: Optimized for all devices

### 🔒 Security & Performance
- **HTTPS Only**: SSL/TLS encryption with ACM certificates
- **API Key Security**: Stored in AWS Secrets Manager
- **Rate Limiting**: Built-in request throttling
- **Health Checks**: Kubernetes liveness/readiness probes
- **Auto Scaling**: Horizontal Pod Autoscaler (HPA)
- **Multi-Architecture**: AMD64 and ARM64 support

### 🌍 Production Features
- **High Availability**: 3 replica pods across AZs
- **Load Balancing**: ALB with health checks
- **Zero Downtime**: Rolling deployments
- **Monitoring**: CloudWatch integration
- **Backup**: Automated EBS snapshots

## 🚀 Deployment Guide

### Prerequisites
- AWS CLI configured
- kubectl installed
- eksctl installed
- Docker with buildx
- Groq API key

### Quick Deploy
```bash
# 1. Clone repository
git clone <repository-url>
cd groq-bot-reborncloud

# 2. Set up EKS cluster
./scripts/setup-groq-bot-eks.sh

# 3. Deploy application
kubectl apply -f k8s/groq-bot-deployment.yaml
kubectl apply -f k8s/groq-bot-ingress.yaml

# 4. Update DNS (replace with your domain)
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://dns-update.json
```

### Environment Variables
```bash
OPENAI_API_KEY=your_groq_api_key_here    # Groq API key
OPENAI_API_HOST=https://api.groq.com/openai
DEFAULT_MODEL=llama-3.1-8b-instant
NODE_ENV=production
```

## 📊 Infrastructure Details

### EKS Cluster Configuration
- **Name**: `groq-bot-eks-cluster`
- **Version**: Kubernetes 1.32
- **Nodes**: 2-4 t3.medium instances
- **Networking**: VPC with NAT Gateway
- **Add-ons**: VPC CNI, CoreDNS, kube-proxy

### Application Deployment
- **Namespace**: `groq-bot`
- **Replicas**: 3 pods
- **Resources**: 256Mi-512Mi RAM, 250m-500m CPU
- **Storage**: Ephemeral (stateless)
- **Service**: ClusterIP on port 80

### Load Balancer Setup
- **Type**: Application Load Balancer (ALB)
- **Scheme**: Internet-facing
- **Target Type**: IP
- **Health Check**: HTTP GET /
- **SSL**: ACM certificate with SNI

## 🔍 Monitoring & Troubleshooting

### Health Checks
```bash
# Check pod status
kubectl get pods -n groq-bot

# View logs
kubectl logs -f deployment/groq-bot -n groq-bot

# Check ingress
kubectl get ingress -n groq-bot

# Test API endpoints
curl https://clone.reborncloud.online/api/models
```

### Common Issues
1. **502 Bad Gateway**: Check pod readiness
2. **SSL Certificate**: Verify ACM certificate
3. **API Errors**: Check Groq API key in secrets
4. **DNS Issues**: Verify Route53 configuration

## 💰 Cost Optimization

### Monthly Costs (Estimated)
- **EKS Control Plane**: $73
- **EC2 Instances**: $60 (2x t3.medium)
- **ALB**: $16
- **NAT Gateway**: $32
- **Data Transfer**: $5-10
- **Total**: ~$186/month

### Cost Savings
- **Groq API**: Free tier (vs OpenAI paid)
- **Spot Instances**: Can reduce EC2 costs by 70%
- **Reserved Instances**: 1-year commitment saves 40%

## 🔄 CI/CD Pipeline

### Build Process
```bash
# Multi-architecture build
docker buildx build --platform linux/amd64,linux/arm64 \
  --tag 739275449845.dkr.ecr.us-east-1.amazonaws.com/groq-bot-clone:v1.1.1 \
  --push .
```

### Deployment Process
```bash
# Update image
kubectl set image deployment/groq-bot \
  groq-bot=739275449845.dkr.ecr.us-east-1.amazonaws.com/groq-bot-clone:v1.1.1 \
  -n groq-bot

# Wait for rollout
kubectl rollout status deployment/groq-bot -n groq-bot
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Groq**: For providing free, fast AI inference
- **Vercel**: For the original Chatbot UI inspiration
- **AWS**: For robust cloud infrastructure
- **Kubernetes**: For container orchestration

## 📞 Support

- **Website**: https://reborncloud.online
- **Email**: support@reborncloud.online
- **Issues**: GitHub Issues tab

---

**Built with ❤️ by Reborncloud Team**

*Empowering conversations with cutting-edge AI technology*
