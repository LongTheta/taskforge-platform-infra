# TaskForge Platform — AWS Infrastructure

Terraform for the TaskForge platform on AWS. Supports **taskforge-backend** and **taskforge-security**.

**Designed with AWS Well-Architected.** REVIEW BEFORE APPLY.

---

## Architecture

| Component | Service |
|-----------|---------|
| Compute | EKS 1.28 (managed node group) |
| Database | RDS PostgreSQL 15 Multi-AZ |
| Registry | ECR (taskforge-backend, taskforge-security) |
| Secrets | Secrets Manager (External Secrets Operator) |
| Network | VPC, 2 AZs, private subnets |

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured
- Sufficient IAM permissions for EKS, RDS, VPC, ECR, Secrets Manager

---

## Quick Start

1. **Copy tfvars:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. **Set variables** in `terraform/terraform.tfvars`:
   - `environment` — dev or prod
   - `db_password` — strong password (or use `TF_VAR_db_password`)

3. **Initialize and plan:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   ```

4. **Apply** when ready:
   ```bash
   terraform apply
   ```

---

## Post-Apply

1. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --name taskforge-<env> --region <region>
   ```

2. **Install ArgoCD** and External Secrets Operator (see taskforge-backend deploy docs).

3. **Update ExternalSecret** to use AWS Secrets Manager — see `deploy/external-secrets-aws-example.yaml`.

4. **Update CI** in taskforge-backend and taskforge-security to push images to ECR (outputs: `ecr_backend_url`, `ecr_security_url`).

---

## Repository Structure

```
taskforge-platform-infra/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── rds.tf
│   ├── ecr.tf
│   ├── secrets.tf
│   └── terraform.tfvars.example
├── deploy/
│   └── external-secrets-aws-example.yaml
├── README.md
├── LICENSE
└── .gitignore
```

---

## Security Defaults

- RDS in private subnets; no 0.0.0.0/0 on workloads
- ECR image scanning on push
- Secrets Manager for DATABASE_URL, SECRET_KEY, API_KEY
- Storage encryption at rest (RDS)
- Required tags on all resources

---

## Related Repositories

| Repo | Purpose |
|------|---------|
| taskforge-backend | Core API, auth, tasks, notes |
| taskforge-security | CVE scanning, remediation, policy gate |
| aws-repo-well-architected-advisor | Design source; solution brief and target architecture |
