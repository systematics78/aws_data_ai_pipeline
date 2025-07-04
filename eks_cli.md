
# EKS Deployment: AWS CLI-based

This script outlines how to deploy an EKS cluster using AWS CLI + `eksctl`.

## ✅ Prerequisites
- `eksctl`, `kubectl`, `aws` CLI
- IAM permissions

## Option 1: Managed Node Group
```bash
eksctl create cluster   --name research-eks   --region eu-central-1   --nodegroup-name managed-ng   --node-type t3.medium   --nodes 2   --nodes-min 1   --nodes-max 3   --managed
```

## Option 2: Self-managed Node Group
Create EKS control plane first:
```bash
eksctl create cluster   --name research-eks   --without-nodegroup
```

Then provision EC2 workers manually and join:
```bash
# Create a Launch Template and Auto Scaling Group
# Use bootstrap.sh with eksctl-generated kubeconfig
```

## 📦 Load Balancer Setup
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

## ✅ Validation
```bash
aws eks update-kubeconfig --name research-eks
kubectl get svc
kubectl get nodes
```

## 🔐 Security
- Use IRSA for service accounts
- Control cluster access via IAM roles and aws-auth ConfigMap
