# Contributing to Reborncloud Groq Bot

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/elsonpulikkan96/groq-bot-reborncloud.git
   cd groq-bot-reborncloud
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Groq API key
   ```

4. **Run development server**
   ```bash
   npm run dev
   ```

## Docker Development

```bash
# Using Docker Compose
docker-compose up --build
```

## Deployment

### Local Kubernetes
```bash
# Create secret
kubectl create secret generic groq-bot-secret \
  --from-literal=OPENAI_API_KEY="your-groq-key"

# Deploy
kubectl apply -f k8s/
```

### Production (AWS EKS)
- Push to master branch triggers automatic deployment via GitHub Actions
- Requires AWS credentials configured in repository secrets

## Code Style

- Use TypeScript for type safety
- Follow ESLint configuration
- Use Prettier for formatting
- Write meaningful commit messages

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## Security

- Never commit API keys or secrets
- Use environment variables for configuration
- Follow security best practices
