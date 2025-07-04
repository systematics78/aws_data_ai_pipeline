
# EKS Deployment: Terraform-based

This deployment provides two options for Amazon EKS:
1. AWS Managed Node Groups
2. Self-managed (custom) EC2 worker nodes

## ✅ Prerequisites
- VPC with subnets
- IAM roles for EKS control plane and nodes
- `kubectl`, `aws`, and `eksctl` installed
- Terraform >= 1.0

## 🧱 Terraform Structure
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── eks_cluster.tf
├── aws_auth.tf
├── node_groups.tf
├── lb_controller.tf
```

## Option 1: Managed Node Groups
```hcl
resource "aws_eks_node_group" "managed" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "managed-ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.private_subnets
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}
```

## Option 2: Self-managed Worker Nodes
```hcl
resource "aws_launch_template" "eks_workers" { ... }

resource "aws_autoscaling_group" "eks_asg" {
  vpc_zone_identifier = var.private_subnets
  launch_template {
    id      = aws_launch_template.eks_workers.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 5
}
```

## 🛡️ Load Balancer Controller
Install IAM policy and IRSA role. Then apply:
```bash
kubectl apply -k github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master
```

## 🚀 Deploy
```bash
terraform init
terraform apply
```

## 🎯 Validate
```bash
aws eks update-kubeconfig --name your-cluster
kubectl get nodes
```
