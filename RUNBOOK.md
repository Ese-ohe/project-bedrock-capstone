# Project Bedrock Runbook

## Overview

This runbook provides operational procedures for deploying, verifying, troubleshooting, scaling, and maintaining the Project Bedrock AWS Retail Store infrastructure deployed on Amazon EKS using Terraform and Kubernetes.

The environment includes:

- Amazon EKS Cluster
- Amazon VPC with Public and Private Subnets
- Amazon RDS MySQL
- Amazon RDS PostgreSQL
- Amazon DynamoDB
- Amazon S3
- AWS Lambda
- Amazon CloudWatch Observability
- GitHub Actions CI/CD
- Kubernetes workloads and ingress resources

## 1. Prerequisites

Ensure the following tools are installed locally:

| Tool | Purpose |
|---|---|
| AWS CLI | AWS authentication and management |
| kubectl | Kubernetes cluster interaction |
| Terraform | Infrastructure provisioning |
| Git | Source control |
| Docker (optional) | Container operations |

## Verify Installations

```bash
aws --version
kubectl version --client
terraform version
git —-version
```

## 2. Clone Repository

```bash
git clone https://github.com/Ese-ohe/project-bedrock-capstone.git
```

cd project-bedrock-capstone

## 3. Configure AWS Credentials
Configure AWS CLI credentials:
```bash
aws configure
```

Provide:

AWS Access Key
AWS Secret Access Key
Region: us-east-1
Output format: json

Verify access:

```bash
aws sts get-caller-identity
```

## 4. Initialize Terraform

Navigate to Terraform root:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Expected result:

Backend initialized
Provider plugins installed
Terraform ready for deployment

## 5. Validate Terraform Configuration

```bash
terraform validate
```

Optional formatting:

```bash
terraform fmt -recursive
```

## 6. Review Infrastructure Plan

```bash
terraform plan
```

Review:

- VPC resources
- EKS cluster
- IAM roles
- RDS resources
- Networking
- Outputs

## 7. Deploy Infrastructure

```bash
terraform apply -auto-approve
```

Terraform provisions:

- VPC
- Public subnets
- Private subnets
- NAT Gateway
- Internet Gateway
- Route tables
- EKS cluster
- Node group
- Security groups
- RDS databases
- DynamoDB tables
- IAM roles and policies

## 8. Configure kubectl Access

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --name project-bedrock-cluster \
  --region us-east-1
```

Verify connectivity:

```bash
kubectl get nodes
```

Expected result:

- EKS worker nodes appear in `Ready` state

## 9. Deploy Kubernetes Workloads

Navigate back to repository root:

```bash
cd ..
```

Deploy application manifests:

```bash
kubectl apply -f k8s/
```

Verify namespace:

```bash
kubectl get ns
```

Verify pods:

```bash
kubectl get pods -n retail-app
```

Expected result:

- All pods should reach `Running` status

## 10. Verify Services

```bash
kubectl get svc -n retail-app
```
Expected result:

- ALB hostname is generated

## 11. Access Retail Store Application

Open the ALB URL in a browser:

```text
http://k8s-retailap-retailap-3c6aa53d7a-826936519.us-east-1.elb.amazonaws.com
```

Verify:

- Home page loads
- Product catalog loads
- Cart functionality works
- Checkout works

---

## 12. Verify CloudWatch Observability

Verify observability pods:

```bash
kubectl get pods -n amazon-cloudwatch
```

Verify Fluent Bit logs:

```bash
kubectl logs -n amazon-cloudwatch daemonset/fluent-bit
```

Verify control plane logs in AWS CloudWatch Console.

---

## 13. Verify Lambda Integration

Upload a test file to S3:

```bash
echo "test upload" > test-image.txt

aws s3 cp test-image.txt \
s3://bedrock-assets-alt-soe-025-3140/
```

Verify Lambda logs:

```bash
aws logs tail /aws/lambda/bedrock-asset-processor \
  --region us-east-1 \
  --since 10m
```

Expected result:

```text
Image received: test-image.txt from bucket: bedrock-assets-alt-soe-025-3140
```

---

## 14. Verify Developer Access

The IAM user:

```text
bedrock-dev-view
```

Has:

- AWS ReadOnlyAccess
- S3 PutObject access
- Kubernetes read-only RBAC

Verification commands:

```bash
kubectl get pods -n retail-app
```

Expected:

```text
Allowed
```

Attempt delete:

```bash
kubectl delete pod <pod-name> -n retail-app
```

Expected:

```text
Denied
```

---

## 15. CI/CD Pipeline

GitHub Actions workflow:

```text
.github/workflows/terraform.yml
```

Pipeline behavior:

| Event | Action |
|---|---|
| Pull Request to `main` | `terraform plan` |
| Merge to `main` | `terraform apply` |

Pipeline uses GitHub Secrets for AWS credentials.

---

## 16. Generate Grading Output

From Terraform directory:

```bash
terraform output -json > ../grading.json
```

Verify file:

```bash
cat ../grading.json
```

Expected outputs:

- `cluster_endpoint`
- `cluster_name`
- `region`
- `vpc_id`
- `assets_bucket_name`

---

## 17. Safe Cost Shutdown Procedure

### 17.1 Delete ALB Ingress

```bash
kubectl delete ingress retail-app-ingress -n retail-app
```

### 17.2 Scale Deployments to Zero

```bash
kubectl scale deployment --all --replicas=0 -n retail-app
```

### 17.3 Scale Node Group to Zero

```bash
aws eks update-nodegroup-config \
  --cluster-name project-bedrock-cluster \
  --nodegroup-name project-bedrock-node-group \
  --scaling-config minSize=0,maxSize=1,desiredSize=0 \
  --region us-east-1
```

### 17.4 Stop RDS Databases

```bash
aws rds stop-db-instance \
  --db-instance-identifier project-bedrock-mysql \
  --region us-east-1

aws rds stop-db-instance \
  --db-instance-identifier project-bedrock-postgres \
  --region us-east-1
```

This reduces AWS costs while preserving infrastructure configuration.

## 18. Restore Environment After Shutdown

## Start Databases

```bash
aws rds start-db-instance \
  --db-instance-identifier project-bedrock-mysql \
  --region us-east-1

aws rds start-db-instance \
  --db-instance-identifier project-bedrock-postgres \
  --region us-east-1
```

## Scale EKS Node Group Back Up

```bash
aws eks update-nodegroup-config \
  --cluster-name project-bedrock-cluster \
  --nodegroup-name project-bedrock-node-group \
  --scaling-config minSize=1,maxSize=3,desiredSize=3 \
  --region us-east-1
```

## Scale Deployments Back Up

```bash
kubectl scale deployment --all --replicas=1 -n retail-app
```

## Recreate Ingress

```bash
kubectl apply -f k8s/ingress/ingress.yaml
```

## Verify Ingress

```bash
kubectl get ingress -n retail-app
```

---

## 19. Cleanup Procedure (Full Destroy)

If full infrastructure removal is required:

```bash
cd terraform

terraform destroy -auto-approve
```

## Warning

This permanently removes infrastructure resources.

---

## 20. Repository Structure

```text
project-bedrock-capstone/
├── .github/workflows/
├── k8s/
├── lambda/
├── terraform/
├── README.md
├── RUNBOOK.md
├── TROUBLESHOOT.md
└── grading.json
```

cd terraform

terraform init