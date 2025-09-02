#!/bin/bash
set -euo pipefail

REGION="us-east-1"
CLUSTER_NAME="groq-bot-eks-cluster"

echo "🚀 Creating new EKS cluster: $CLUSTER_NAME"

# Create EKS cluster
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --nodegroup-name groq-bot-workers \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4 \
    --managed

# Associate OIDC provider
eksctl utils associate-iam-oidc-provider --region=$REGION --cluster=$CLUSTER_NAME --approve

# Create service account for ALB controller
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name GroqBotALBControllerRole \
    --attach-policy-arn=arn:aws:iam::739275449845:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve \
    --region=$REGION

# Install ALB controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

echo "✅ EKS cluster $CLUSTER_NAME ready!"
