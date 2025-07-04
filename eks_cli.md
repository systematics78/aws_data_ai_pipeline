
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
#!/bin/bash
set -ex

# Replace with your actual cluster name and region
CLUSTER_NAME="my-cluster"
REGION="eu-central-1"

# Install required packages
yum update -y
yum install -y aws-cli curl jq

# Get kubelet and aws-iam-authenticator
mkdir -p /etc/eks
cat <<EOF > /etc/eks/bootstrap.sh
#!/bin/bash
/etc/eks/bootstrap.sh ${CLUSTER_NAME}
EOF
chmod +x /etc/eks/bootstrap.sh

# Run bootstrap script
/etc/eks/bootstrap.sh ${CLUSTER_NAME} --kubelet-extra-args '--node-labels=eks/nodegroup=custom-nodes'

# Here’s a sample user data block to paste into the EC2 launch template (or ASG). This will auto-join the instance to your EKS cluster at boot:

#!/bin/bash
set -o xtrace

# Variables
CLUSTER_NAME="my-cluster"
REGION="eu-central-1"
B64_CLUSTER_CA=<INSERT_BASE64_CA_FROM_AWS>
API_SERVER_URL=<INSERT_API_SERVER_URL_FROM_DESCRIBE_CLUSTER>
NODE_ROLE_ARN=arn:aws:iam::<ACCOUNT>:role/<EC2_NODE_ROLE>

# Install deps
yum update -y
yum install -y aws-cli jq curl

# Install container runtime and kubelet
amazon-linux-extras enable docker
yum install -y docker
systemctl start docker && systemctl enable docker

curl -o /etc/yum.repos.d/eks.repo https://amazon-eks.s3.${REGION}.amazonaws.com/latest/eks.repo
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet

# Write kubelet config
mkdir -p /var/lib/kubelet
cat <<EOF > /var/lib/kubelet/kubeconfig
apiVersion: v1
clusters:
- cluster:
    server: ${API_SERVER_URL}
    certificate-authority-data: ${B64_CLUSTER_CA}
  name: eks
contexts:
- context:
    cluster: eks
    user: eks
  name: eks
current-context: eks
kind: Config
preferences: {}
users:
- name: eks
  user:
    exec:
      apiVersion: "client.authentication.k8s.io/v1alpha1"
      command: "/usr/bin/aws"
      args:
        - "eks"
        - "get-token"
        - "--region"
        - "${REGION}"
        - "--cluster-name"
        - "${CLUSTER_NAME}"
EOF

# Bootstrap and start kubelet
/etc/eks/bootstrap.sh ${CLUSTER_NAME} --kubelet-extra-args '--node-labels=eks/nodegroup=custom'

systemctl start kubelet

# Required AWS Commands (to extract values)
# Get the CA cert and API server endpoint:

aws eks describe-cluster --name my-cluster --region eu-central-1 \
  --query "cluster.{endpoint:endpoint,ca:certificateAuthority.data}" \
  --output text

# IAM Role for EC2 Worker Nodes (Trust + Permissions)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

# Attach the following managed policies:
- AmazonEKSWorkerNodePolicy
- AmazonEC2ContainerRegistryReadOnly
- AmazonEKS_CNI_Policy

# Add Worker Nodes to aws-auth ConfigMap (if not using eksctl)
kubectl edit configmap aws-auth -n kube-system

# Append under mapRoles:
  - rolearn: arn:aws:iam::<ACCOUNT_ID>:role/<EC2_NODE_ROLE>
    username: system:node:{{EC2PrivateDNSName}}
    groups:
      - system:bootstrappers
      - system:nodes

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
