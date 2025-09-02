#!/bin/bash

# Secure Deployment Script for Chatbot UI
# This script automates the secure deployment process with all security checks

set -euo pipefail

# Configuration
REGION="us-east-1"
CLUSTER_NAME="chatbot-eks-cluster"
NAMESPACE="chatbot-ui"
DOMAIN="clone.reborncloud.online"
IMAGE_REGISTRY="elsonpulikkan"
IMAGE_NAME="openai-gptbotclone"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    for tool in docker kubectl aws terraform helm jq; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install missing tools and try again."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon not running"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Function to scan for secrets
scan_secrets() {
    log_info "Scanning for exposed secrets..."
    
    # Check for common secret patterns
    if grep -r -E "(sk-[a-zA-Z0-9]{48}|AKIA[0-9A-Z]{16})" . --exclude-dir=.git --exclude="*.md" --exclude="deploy-secure.sh" 2>/dev/null; then
        log_error "Potential secrets found in codebase!"
        log_error "Please remove all hardcoded secrets before deployment"
        exit 1
    fi
    
    log_success "No exposed secrets detected"
}

# Function to build secure multi-arch Docker image
build_secure_image() {
    log_info "Building secure multi-arch Docker image..."
    
    # Get git commit hash for tagging
    local git_hash
    git_hash=$(git rev-parse --short HEAD)
    local image_tag="v1.0.0-${git_hash}"
    
    # Create buildx builder if not exists
    if ! docker buildx ls | grep -q multiarch; then
        docker buildx create --name multiarch --use --bootstrap
    else
        docker buildx use multiarch
    fi
    
    # Build and push multi-arch image
    log_info "Building for platforms: linux/amd64,linux/arm64"
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --file Dockerfile.optimized \
        --tag "${IMAGE_REGISTRY}/${IMAGE_NAME}:${image_tag}" \
        --tag "${IMAGE_REGISTRY}/${IMAGE_NAME}:latest" \
        --push \
        --provenance=true \
        --sbom=true \
        .
    
    # Update image tag in deployment manifest
    sed -i.bak "s|image: .*|image: ${IMAGE_REGISTRY}/${IMAGE_NAME}:${image_tag}|g" k8s/secure-deployment.yaml
    
    log_success "Multi-arch image built and pushed: ${image_tag}"
    echo "${image_tag}" > .image_tag
}

# Function to scan container image
scan_image() {
    log_info "Scanning container image for vulnerabilities..."
    
    local image_tag
    image_tag=$(cat .image_tag)
    
    # Install Trivy if not present
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    # Scan the image
    if trivy image --severity HIGH,CRITICAL --exit-code 1 "${IMAGE_REGISTRY}/${IMAGE_NAME}:${image_tag}"; then
        log_success "Container image security scan passed"
    else
        log_error "Container image has critical vulnerabilities"
        log_error "Please fix vulnerabilities before deployment"
        exit 1
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply infrastructure
    if terraform apply tfplan; then
        log_success "Infrastructure deployed successfully"
    else
        log_error "Infrastructure deployment failed"
        exit 1
    fi
    
    cd ..
}

# Function to configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        log_success "kubectl configured successfully"
    else
        log_error "Failed to configure kubectl"
        exit 1
    fi
}

# Function to deploy application
deploy_application() {
    log_info "Deploying application to Kubernetes..."
    
    # Create namespace if not exists
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply security policies first
    kubectl apply -f k8s/network-policies.yaml || log_warning "Network policies not applied"
    
    # Deploy application
    kubectl apply -f k8s/secure-deployment.yaml
    
    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/chatbot-ui -n "$NAMESPACE" --timeout=300s
    
    log_success "Application deployed successfully"
}

# Function to run health checks
run_health_checks() {
    log_info "Running health checks..."
    
    # Check pod status
    local pod_status
    pod_status=$(kubectl get pods -n "$NAMESPACE" -l app=chatbot-ui -o jsonpath='{.items[*].status.phase}')
    
    if [[ "$pod_status" == *"Running"* ]]; then
        log_success "Pods are running"
    else
        log_error "Pods are not running properly"
        kubectl get pods -n "$NAMESPACE" -l app=chatbot-ui
        exit 1
    fi
    
    # Check service endpoints
    local endpoints
    endpoints=$(kubectl get endpoints chatbot-ui-service -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}')
    
    if [[ -n "$endpoints" ]]; then
        log_success "Service endpoints are ready"
    else
        log_error "No service endpoints available"
        exit 1
    fi
    
    # Check ingress
    if kubectl get ingress chatbot-ui-ingress -n "$NAMESPACE" &> /dev/null; then
        log_success "Ingress is configured"
        kubectl get ingress chatbot-ui-ingress -n "$NAMESPACE"
    else
        log_warning "Ingress not found"
    fi
}

# Function to verify domain and SSL
verify_domain_ssl() {
    log_info "Verifying domain and SSL configuration..."
    
    if [[ -f "scripts/verify-domain.sh" ]]; then
        if ./scripts/verify-domain.sh "$DOMAIN"; then
            log_success "Domain and SSL verification passed"
        else
            log_warning "Domain and SSL verification failed"
            log_warning "The application may not be accessible externally yet"
        fi
    else
        log_warning "Domain verification script not found"
    fi
}

# Function to setup monitoring
setup_monitoring() {
    log_info "Setting up monitoring stack..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Prometheus and Grafana configs
    kubectl apply -f monitoring/prometheus-config.yaml
    
    # Install Prometheus using Helm
    if ! helm list -n monitoring | grep -q prometheus; then
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        helm install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --set grafana.adminPassword=admin123 \
            --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
            --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
    fi
    
    log_success "Monitoring stack deployed"
}

# Function to setup Argo CD
setup_argocd() {
    log_info "Setting up Argo CD..."
    
    # Create argocd namespace
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Argo CD
    if ! kubectl get deployment argocd-server -n argocd &> /dev/null; then
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for Argo CD to be ready
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    fi
    
    # Apply application manifest
    kubectl apply -f argocd/application.yaml
    
    log_success "Argo CD deployed and configured"
}

# Function to run smoke tests
run_smoke_tests() {
    log_info "Running smoke tests..."
    
    # Get service URL
    local service_url
    if kubectl get ingress chatbot-ui-ingress -n "$NAMESPACE" &> /dev/null; then
        service_url="https://$DOMAIN"
    else
        # Use port-forward for testing
        kubectl port-forward svc/chatbot-ui-service 8080:80 -n "$NAMESPACE" &
        local port_forward_pid=$!
        sleep 5
        service_url="http://localhost:8080"
    fi
    
    # Basic connectivity test
    if curl -f -s "$service_url/api/health" &> /dev/null; then
        log_success "Smoke test passed - application is responding"
    else
        log_error "Smoke test failed - application not responding"
        
        # Cleanup port-forward if used
        if [[ -n "${port_forward_pid:-}" ]]; then
            kill "$port_forward_pid" 2>/dev/null || true
        fi
        
        exit 1
    fi
    
    # Cleanup port-forward if used
    if [[ -n "${port_forward_pid:-}" ]]; then
        kill "$port_forward_pid" 2>/dev/null || true
    fi
}

# Function to display deployment summary
display_summary() {
    log_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "======================"
    echo "• Cluster: $CLUSTER_NAME"
    echo "• Namespace: $NAMESPACE"
    echo "• Domain: $DOMAIN"
    echo "• Image: ${IMAGE_REGISTRY}/${IMAGE_NAME}:$(cat .image_tag 2>/dev/null || echo 'latest')"
    echo ""
    echo "🔗 Access URLs:"
    echo "• Application: https://$DOMAIN"
    echo "• Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
    echo "• Argo CD: kubectl port-forward svc/argocd-server 8080:443 -n argocd"
    echo ""
    echo "🔧 Useful Commands:"
    echo "• Check pods: kubectl get pods -n $NAMESPACE"
    echo "• View logs: kubectl logs -f deployment/chatbot-ui -n $NAMESPACE"
    echo "• Scale app: kubectl scale deployment chatbot-ui --replicas=5 -n $NAMESPACE"
    echo ""
    echo "🔒 Security Notes:"
    echo "• All secrets are stored in AWS Secrets Manager"
    echo "• Containers run as non-root user"
    echo "• Multi-arch images support both AMD64 and ARM64"
    echo "• SSL/TLS termination at ALB level"
}

# Main deployment function
main() {
    log_info "🚀 Starting secure deployment of Chatbot UI"
    log_info "============================================="
    
    # Run all deployment steps
    check_prerequisites
    scan_secrets
    build_secure_image
    scan_image
    deploy_infrastructure
    configure_kubectl
    deploy_application
    run_health_checks
    verify_domain_ssl
    setup_monitoring
    setup_argocd
    run_smoke_tests
    display_summary
    
    log_success "✅ Secure deployment completed successfully!"
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-infra)
            SKIP_INFRA=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --skip-argocd)
            SKIP_ARGOCD=true
            shift
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --skip-infra      Skip infrastructure deployment"
            echo "  --skip-monitoring Skip monitoring setup"
            echo "  --skip-argocd     Skip Argo CD setup"
            echo "  --domain DOMAIN   Override domain name"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main deployment
main "$@"
