#!/bin/bash

# Domain and SSL Verification Script
# Usage: ./verify-domain.sh clone.reborncloud.online

set -euo pipefail

DOMAIN="${1:-clone.reborncloud.online}"
REGION="us-east-1"

echo "🔍 Verifying domain configuration for: $DOMAIN"
echo "=================================================="

# Function to check DNS resolution
check_dns() {
    echo "📡 Checking DNS resolution..."
    if nslookup "$DOMAIN" > /dev/null 2>&1; then
        echo "✅ DNS resolution successful"
        nslookup "$DOMAIN"
    else
        echo "❌ DNS resolution failed - Domain not found (NXDOMAIN)"
        echo "🔧 Required actions:"
        echo "   1. Create Route53 hosted zone for reborncloud.online"
        echo "   2. Add A record for clone.reborncloud.online"
        echo "   3. Update nameservers at domain registrar"
        return 1
    fi
}

# Function to check SSL certificate
check_ssl() {
    echo "🔒 Checking SSL certificate..."
    if timeout 10 openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
        echo "✅ SSL certificate found and valid"
        echo "Certificate details:"
        timeout 10 openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
    else
        echo "❌ SSL certificate check failed"
        echo "🔧 Required actions:"
        echo "   1. Create ACM certificate in $REGION"
        echo "   2. Validate certificate via DNS"
        echo "   3. Associate with ALB"
        return 1
    fi
}

# Function to check HTTP/HTTPS connectivity
check_connectivity() {
    echo "🌐 Checking HTTP/HTTPS connectivity..."
    
    # Check HTTP (should redirect to HTTPS)
    if curl -I -s -m 10 "http://$DOMAIN" | grep -q "301\|302"; then
        echo "✅ HTTP redirect to HTTPS working"
    else
        echo "⚠️  HTTP redirect not configured"
    fi
    
    # Check HTTPS
    if curl -I -s -m 10 "https://$DOMAIN" | grep -q "200"; then
        echo "✅ HTTPS connectivity successful"
        echo "Response headers:"
        curl -I -s -m 10 "https://$DOMAIN" | head -5
    else
        echo "❌ HTTPS connectivity failed"
        return 1
    fi
}

# Function to check ALB configuration
check_alb() {
    echo "🔧 Checking ALB configuration..."
    
    # Get ALB ARN from tags or name
    ALB_ARN=$(aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[?contains(LoadBalancerName, 'chatbot') || contains(Tags[?Key=='Name'].Value, 'chatbot')].LoadBalancerArn" --output text 2>/dev/null || echo "")
    
    if [[ -n "$ALB_ARN" ]]; then
        echo "✅ ALB found: $ALB_ARN"
        
        # Check listeners
        echo "Checking ALB listeners..."
        aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --region "$REGION" --query "Listeners[*].[Port,Protocol,DefaultActions[0].Type]" --output table
        
        # Check target groups
        echo "Checking target group health..."
        TG_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --region "$REGION" --query "TargetGroups[0].TargetGroupArn" --output text)
        if [[ -n "$TG_ARN" && "$TG_ARN" != "None" ]]; then
            aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region "$REGION" --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]" --output table
        fi
    else
        echo "❌ ALB not found"
        echo "🔧 Required actions:"
        echo "   1. Deploy ALB Ingress Controller"
        echo "   2. Apply Ingress manifest"
        echo "   3. Verify target group registration"
    fi
}

# Function to check ACM certificate
check_acm() {
    echo "📜 Checking ACM certificate..."
    
    CERT_ARN=$(aws acm list-certificates --region "$REGION" --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn" --output text 2>/dev/null || echo "")
    
    if [[ -n "$CERT_ARN" && "$CERT_ARN" != "None" ]]; then
        echo "✅ ACM certificate found: $CERT_ARN"
        
        # Check certificate status
        aws acm describe-certificate --certificate-arn "$CERT_ARN" --region "$REGION" --query "{Status:Status,DomainName:DomainName,InUse:InUseBy,Expiry:NotAfter}" --output table
    else
        echo "❌ ACM certificate not found"
        echo "🔧 Required actions:"
        echo "   1. Create ACM certificate for $DOMAIN"
        echo "   2. Validate via DNS method"
        echo "   3. Associate with ALB listener"
    fi
}

# Function to check Kubernetes ingress
check_k8s_ingress() {
    echo "☸️  Checking Kubernetes Ingress..."
    
    if kubectl get ingress chatbot-ui-ingress -n chatbot-ui >/dev/null 2>&1; then
        echo "✅ Kubernetes Ingress found"
        kubectl get ingress chatbot-ui-ingress -n chatbot-ui -o wide
        
        # Check ingress annotations
        echo "Ingress annotations:"
        kubectl get ingress chatbot-ui-ingress -n chatbot-ui -o jsonpath='{.metadata.annotations}' | jq .
    else
        echo "❌ Kubernetes Ingress not found"
        echo "🔧 Required actions:"
        echo "   1. Apply secure-deployment.yaml"
        echo "   2. Verify ALB Ingress Controller is running"
        echo "   3. Check ingress class configuration"
    fi
}

# Main execution
main() {
    echo "Starting comprehensive domain verification..."
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    
    local exit_code=0
    
    # Run all checks
    check_dns || exit_code=1
    echo ""
    
    check_ssl || exit_code=1
    echo ""
    
    check_connectivity || exit_code=1
    echo ""
    
    check_alb || exit_code=1
    echo ""
    
    check_acm || exit_code=1
    echo ""
    
    check_k8s_ingress || exit_code=1
    echo ""
    
    # Summary
    echo "=================================================="
    if [[ $exit_code -eq 0 ]]; then
        echo "🎉 All checks passed! Domain is properly configured."
    else
        echo "⚠️  Some checks failed. Please review the output above."
        echo ""
        echo "📋 Quick remediation checklist:"
        echo "1. Fix DNS resolution (Route53 configuration)"
        echo "2. Create and validate ACM certificate"
        echo "3. Deploy ALB with proper listeners"
        echo "4. Apply Kubernetes Ingress manifest"
        echo "5. Verify target group health"
    fi
    
    return $exit_code
}

# Check dependencies
command -v nslookup >/dev/null 2>&1 || { echo "❌ nslookup not found. Please install bind-utils."; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "❌ openssl not found. Please install openssl."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "❌ curl not found. Please install curl."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Please install aws-cli."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Please install kubectl."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq not found. Please install jq."; exit 1; }

# Run main function
main "$@"
