# Project Bedrock Troubleshooting Guide

## Overview

This troubleshooting guide provides common issues, root causes, verification steps, and resolutions for the Project Bedrock AWS Retail Store deployment running on Amazon EKS.

The environment includes:

- Amazon EKS
- Terraform Infrastructure
- Kubernetes Workloads
- Amazon RDS
- Amazon DynamoDB
- Amazon S3
- AWS Lambda
- CloudWatch Observability
- GitHub Actions CI/CD

---

# 1. Terraform Issues

## Problem: Terraform Initialization Fails

### Symptoms

```bash
terraform init
```

Returns:

```text
Error: Failed to download modules
```

or

```text
Backend initialization failed
```

### Possible Causes

- Internet connectivity issues
- Invalid backend configuration
- AWS credentials missing
- Incorrect AWS region

### Resolution

Verify AWS credentials:

```bash
aws sts get-caller-identity
```

Reconfigure credentials if necessary:

```bash
aws configure
```

Retry initialization:

```bash
terraform init -reconfigure
```

---

## Problem: Terraform Apply Fails

### Symptoms

```bash
terraform apply
```

Returns:

```text
Error creating EKS Cluster
```

or

```text
AccessDenied
```

### Possible Causes

- Insufficient IAM permissions
- Existing conflicting resources
- AWS service quota exceeded

### Resolution

Validate Terraform configuration:

```bash
terraform validate
```

Review execution plan:

```bash
terraform plan
```

Verify IAM permissions for:

- EKS
- EC2
- IAM
- VPC
- RDS
- DynamoDB
- CloudWatch

---

# 2. Kubernetes Cluster Issues

## Problem: kubectl Cannot Connect to Cluster

### Symptoms

```bash
kubectl get nodes
```

Returns:

```text
Unable to connect to the server
```

### Possible Causes

- kubeconfig not updated
- EKS cluster unavailable
- AWS authentication expired

### Resolution

Update kubeconfig:

```bash
aws eks update-kubeconfig \
  --name project-bedrock-cluster \
  --region us-east-1
```

Verify cluster access:

```bash
kubectl cluster-info
```

---

## Problem: Nodes Not Ready

### Symptoms

```bash
kubectl get nodes
```

Shows:

```text
NotReady
```

### Possible Causes

- Node group scaling issue
- Worker nodes still provisioning
- Networking issue
- IAM role issue

### Resolution

Check node group:

```bash
aws eks describe-nodegroup \
  --cluster-name project-bedrock-cluster \
  --nodegroup-name project-bedrock-node-group \
  --region us-east-1
```

Scale node group if needed:

```bash
aws eks update-nodegroup-config \
  --cluster-name project-bedrock-cluster \
  --nodegroup-name project-bedrock-node-group \
  --scaling-config minSize=1,maxSize=3,desiredSize=3 \
  --region us-east-1
```

---

# 3. Pod Issues

## Problem: Pods Stuck in Pending State

### Symptoms

```bash
kubectl get pods -n retail-app
```

Shows:

```text
Pending
```

### Possible Causes

- No available worker nodes
- Insufficient CPU or memory
- Storage provisioning issue

### Resolution

Describe pod:

```bash
kubectl describe pod <pod-name> -n retail-app
```

Check node availability:

```bash
kubectl get nodes
```

Verify node resources:

```bash
kubectl top nodes
```

---

## Problem: Pods in CrashLoopBackOff

### Symptoms

```bash
kubectl get pods -n retail-app
```

Shows:

```text
CrashLoopBackOff
```

### Possible Causes

- Application startup failure
- Database connectivity issue
- Environment variable issue

### Resolution

Check pod logs:

```bash
kubectl logs <pod-name> -n retail-app
```

Describe pod:

```bash
kubectl describe pod <pod-name> -n retail-app
```

Restart deployment:

```bash
kubectl rollout restart deployment <deployment-name> -n retail-app
```

---

# 4. Application Access Issues

## Problem: Retail Store URL Not Accessible

### Symptoms

Browser shows:

```text
503 Service Unavailable
```

or

```text
This site cannot be reached
```

### Possible Causes

- ALB not provisioned
- Ingress misconfiguration
- Pods unavailable
- Services not exposed

### Resolution

Check ingress:

```bash
kubectl get ingress -n retail-app
```

Describe ingress:

```bash
kubectl describe ingress retail-app-ingress -n retail-app
```

Verify services:

```bash
kubectl get svc -n retail-app
```

Verify pods:

```bash
kubectl get pods -n retail-app
```

---

# 5. CloudWatch Issues

## Problem: Logs Not Appearing in CloudWatch

### Symptoms

No logs visible in:

- CloudWatch Log Groups
- Container Insights

### Possible Causes

- CloudWatch agent failure
- Fluent Bit failure
- IAM permissions missing

### Resolution

Check observability pods:

```bash
kubectl get pods -n amazon-cloudwatch
```

Check Fluent Bit logs:

```bash
kubectl logs -n amazon-cloudwatch daemonset/fluent-bit
```

Restart observability components:

```bash
kubectl rollout restart daemonset fluent-bit -n amazon-cloudwatch
```

---

# 6. Lambda and S3 Issues

## Problem: Lambda Not Triggering from S3

### Symptoms

Files upload successfully to S3 but Lambda logs show no events.

### Possible Causes

- Missing S3 notification configuration
- Lambda permission issue
- Wrong bucket name

### Resolution

Verify bucket notification:

```bash
aws s3api get-bucket-notification-configuration \
  --bucket bedrock-assets-alt-soe-025-3140
```

Verify Lambda permissions:

```bash
aws lambda get-policy \
  --function-name bedrock-asset-processor \
  --region us-east-1
```

Upload test file:

```bash
echo "test" > test.txt

aws s3 cp test.txt \
s3://bedrock-assets-alt-soe-025-3140/
```

Check logs:

```bash
aws logs tail /aws/lambda/bedrock-asset-processor \
  --region us-east-1 \
  --since 10m
```

---

# 7. RDS Issues

## Problem: Application Cannot Connect to Database

### Symptoms

Application logs show:

```text
Connection refused
```

or

```text
Database unavailable
```

### Possible Causes

- RDS stopped
- Security group issue
- Incorrect credentials

### Resolution

Verify RDS status:

```bash
aws rds describe-db-instances \
  --region us-east-1
```

Start database if stopped:

```bash
aws rds start-db-instance \
  --db-instance-identifier project-bedrock-mysql \
  --region us-east-1
```

Verify security groups allow EKS node access.

---

# 8. GitHub Actions Pipeline Issues

## Problem: GitHub Actions Failing

### Symptoms

Pipeline shows:

```text
Terraform init failed
```

or

```text
AccessDenied
```

### Possible Causes

- Incorrect GitHub Secrets
- Expired AWS credentials
- Terraform syntax errors

### Resolution

Verify repository secrets:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

Validate Terraform locally:

```bash
terraform validate
```

Review GitHub Actions logs from repository Actions tab.

---

# 9. Safe Recovery Procedure

If workloads were scaled down to save costs:

## Restart Databases

```bash
aws rds start-db-instance \
  --db-instance-identifier project-bedrock-mysql \
  --region us-east-1

aws rds start-db-instance \
  --db-instance-identifier project-bedrock-postgres \
  --region us-east-1
```

## Restore Node Group

```bash
aws eks update-nodegroup-config \
  --cluster-name project-bedrock-cluster \
  --nodegroup-name project-bedrock-node-group \
  --scaling-config minSize=1,maxSize=3,desiredSize=3 \
  --region us-east-1
```

## Restore Workloads

```bash
kubectl scale deployment --all --replicas=1 -n retail-app
```

## Recreate Ingress

```bash
kubectl apply -f k8s/ingress/ingress.yaml
```

Verify:

```bash
kubectl get ingress -n retail-app
```

---

# 10. Useful Verification Commands

## Kubernetes

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

## Terraform

```bash
terraform validate
terraform plan
terraform output
```

## AWS

```bash
aws sts get-caller-identity
aws eks list-clusters
aws rds describe-db-instances
aws s3 ls
```

---

# 11. Emergency Full Cleanup

If complete teardown is required:

```bash
cd terraform

terraform destroy -auto-approve
```

## Warning

This permanently deletes infrastructure resources.