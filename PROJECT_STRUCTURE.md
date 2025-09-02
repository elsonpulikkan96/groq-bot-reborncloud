# 📁 Project Structure - Reborncloud Groq Bot

## Directory Overview

```
groq-bot-reborncloud/
├── 📁 components/           # React UI Components
│   ├── Chat/               # Main chat interface
│   ├── Chatbar/           # Conversation sidebar
│   ├── Promptbar/         # Prompt management
│   ├── Mobile/            # Mobile-specific components
│   └── Markdown/          # Markdown rendering
│
├── 📁 pages/               # Next.js Pages & API Routes
│   ├── api/               # Backend API endpoints
│   │   ├── chat.ts        # Chat completion API
│   │   ├── models.ts      # Available models API
│   │   └── google.ts      # Google search integration
│   ├── _app.tsx           # App configuration & branding
│   └── index.tsx          # Main chat interface
│
├── 📁 types/               # TypeScript Definitions
│   ├── chat.ts            # Chat-related types
│   ├── openai.ts          # AI model types
│   ├── plugin.ts          # Plugin system types
│   └── export.ts          # Data export types
│
├── 📁 utils/               # Utility Functions
│   ├── app/               # Application utilities
│   │   ├── const.ts       # Constants & configuration
│   │   ├── api.ts         # API helpers
│   │   └── clean.ts       # Data cleaning utilities
│   └── server/            # Server-side utilities
│       └── index.ts       # OpenAI streaming logic
│
├── 📁 k8s/                 # Kubernetes Manifests
│   ├── groq-bot-deployment.yaml  # Main deployment
│   └── groq-bot-ingress.yaml     # ALB ingress
│
├── 📁 scripts/             # Deployment Scripts
│   └── setup-groq-bot-eks.sh    # EKS cluster setup
│
├── 📁 styles/              # CSS Styles
│   └── globals.css        # Global Tailwind styles
│
├── 📁 public/              # Static Assets
│   ├── favicon.ico        # Site icon
│   └── locales/           # Internationalization
│
├── 📄 README.md            # Main documentation
├── 📄 DEPLOYMENT.md        # Deployment guide
├── 📄 PROJECT_STRUCTURE.md # This file
├── 📄 package.json         # Dependencies & scripts
├── 📄 Dockerfile.simple    # Container build
├── 📄 next.config.js       # Next.js configuration
├── 📄 tailwind.config.js   # Tailwind CSS config
└── 📄 tsconfig.json        # TypeScript config
```

## Key Files Explained

### 🎨 Frontend Components

#### `components/Chat/Chat.tsx`
- Main chat interface component
- Handles message rendering and user input
- Manages conversation state and streaming

#### `components/Chatbar/Chatbar.tsx`
- Sidebar for conversation management
- Folder organization and search
- Conversation history and settings

#### `components/Promptbar/Promptbar.tsx`
- Prompt template management
- Custom prompt creation and editing
- Prompt sharing and organization

### 🔧 Backend API Routes

#### `pages/api/chat.ts`
- **Purpose**: Handle chat completion requests
- **Features**: 
  - Groq API integration
  - Token counting and management
  - Streaming response handling
  - Error handling and validation

#### `pages/api/models.ts`
- **Purpose**: Fetch available AI models
- **Features**:
  - Dynamic model discovery
  - Groq-specific model mapping
  - Fallback model handling
  - Model capability information

### 📝 Type Definitions

#### `types/openai.ts`
- AI model interfaces and enums
- Groq model definitions
- Token limits and capabilities
- Model selection logic

#### `types/chat.ts`
- Chat message structures
- Conversation management types
- User interaction interfaces
- Export/import formats

### 🛠️ Utility Functions

#### `utils/app/const.ts`
- Environment configuration
- API endpoints and hosts
- Default model settings
- System prompts

#### `utils/server/index.ts`
- OpenAI/Groq API streaming
- Error handling classes
- Response parsing logic
- Authentication management

### 🚀 Deployment Configuration

#### `k8s/groq-bot-deployment.yaml`
- Kubernetes deployment manifest
- Pod specifications and replicas
- Environment variables and secrets
- Resource limits and requests
- Health checks and probes

#### `k8s/groq-bot-ingress.yaml`
- ALB ingress configuration
- SSL/TLS certificate setup
- Domain routing rules
- Health check endpoints

#### `Dockerfile.simple`
- Multi-stage container build
- Node.js 18 Alpine base
- Production optimization
- Security hardening

## 🔄 Data Flow

```
User Input → Chat Component → API Route → Groq API → Streaming Response → UI Update
     ↓              ↓            ↓           ↓              ↓              ↓
  React State → Message Queue → Token Count → AI Model → Parsed Text → Markdown Render
```

## 🎯 Key Features Implementation

### 1. **Real-time Streaming**
- `utils/server/index.ts` - Server-sent events
- `components/Chat/Chat.tsx` - Client-side streaming
- `pages/api/chat.ts` - API endpoint handling

### 2. **Model Management**
- `types/openai.ts` - Model definitions
- `pages/api/models.ts` - Dynamic model loading
- `utils/app/const.ts` - Default configurations

### 3. **Conversation Persistence**
- `utils/app/conversation.ts` - Local storage
- `components/Chatbar/` - UI management
- `types/chat.ts` - Data structures

### 4. **Internationalization**
- `public/locales/` - Translation files
- `next-i18next.config.js` - i18n configuration
- `pages/_app.tsx` - Language provider

## 🔐 Security Implementation

### Environment Variables
```typescript
// Secure API key handling
OPENAI_API_KEY: process.env.OPENAI_API_KEY
OPENAI_API_HOST: process.env.OPENAI_API_HOST
```

### Input Validation
```typescript
// Token limit enforcement
if (tokenCount + tokens.length + 1000 > model.tokenLimit) {
  break;
}
```

### Error Handling
```typescript
// Graceful error management
catch (error) {
  if (error instanceof OpenAIError) {
    return new Response('Error', { status: 500, statusText: error.message });
  }
}
```

## 📊 Performance Optimizations

### 1. **Edge Runtime**
- API routes use Edge Runtime for faster cold starts
- Reduced memory footprint and latency

### 2. **Token Management**
- Efficient token counting with tiktoken
- Smart conversation truncation
- Memory usage optimization

### 3. **Streaming Responses**
- Real-time user feedback
- Reduced perceived latency
- Better user experience

### 4. **Container Optimization**
- Multi-stage Docker builds
- Alpine Linux base image
- Production-only dependencies

---

**Last Updated**: September 2, 2025  
**Maintainer**: Reborncloud Team
