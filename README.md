# TaskForge Platform — AWS Infrastructure

Terraform for the TaskForge platform on AWS. Supports **taskforge-backend** and **taskforge-security**.

**Designed with AWS Well-Architected.** REVIEW BEFORE APPLY.

---

## Design Source

This infrastructure was produced using **aws-repo-well-architected-advisor** as the design source. The advisor repo (kept as a sibling, e.g. `../aws-repo-well-architected-advisor`) provides:

- **Solution brief and target architecture** — Reference design for the TaskForge platform on AWS
- **Well-Architected pillars** — Operational excellence, security, reliability, performance efficiency, cost optimization
- **Evidence model and recommendation patterns** — Used to assess the stack and generate Terraform patches

The assessment workflow reads the advisor for guidance, evaluates taskforge-backend and taskforge-security, and applies incremental fixes to this repo. The advisor repo is referenced but never modified.

---

## Architecture

| Component | Service |
|-----------|---------|
| **Network** | VPC, 2 AZs, public + private subnets, route tables, NAT, IGW |
| **Compute** | EKS 1.28 (managed node group) |
| **Database** | RDS PostgreSQL 15 Multi-AZ |
| **Registry** | ECR (taskforge-backend, taskforge-security) |
| **Secrets** | Secrets Manager + KMS (External Secrets Operator) |
| **IAM** | IRSA (ESO, AWS Load Balancer Controller), ECR push, RDS connect |
| **Security** | KMS keys, VPC Flow Logs, CloudTrail, subnet tags for ALB discovery |

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured
- **IAM permissions:** Attach the policy in `terraform/iam-execution-policy.json` to the role/user running Terraform. See [docs/iam-execution-requirements.md](docs/iam-execution-requirements.md).

---

## Quick Start

1. **Bootstrap remote state** (one-time per account/region):
   ```bash
   ./scripts/bootstrap-backend.sh
   ```

2. **Configure backend:**
   ```bash
   cp terraform/backend.hcl.example terraform/backend.hcl
   # Edit backend.hcl if using different bucket/table/region
   ```

3. **Copy tfvars:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

4. **Set variables** in `terraform/terraform.tfvars`:
   - `environment` — dev or prod
   - `db_password` — strong password (or use `TF_VAR_db_password`)
   - `eks_endpoint_public_access` — set `false` for prod (restricts kubectl to VPC)

5. **Initialize and plan:**
   ```bash
   cd terraform
   terraform init -backend-config=backend.hcl
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

2. **Annotate ESO service account** with IRSA role: `kubectl annotate sa external-secrets -n external-secrets eks.amazonaws.com/role-arn=$(terraform output -raw eso_iam_role_arn)`

3. **Install AWS Load Balancer Controller** (Helm): uses `lb_controller_iam_role_arn` for IRSA. Creates ALBs from K8s Ingress.

4. **Install ArgoCD** and External Secrets Operator (see taskforge-backend deploy docs).

5. **Update ExternalSecret** to use AWS Secrets Manager — see `deploy/external-secrets-aws-example.yaml`.

6. **Update CI** in taskforge-backend and taskforge-security to push images to ECR (outputs: `ecr_backend_url`, `ecr_security_url`). Attach `ecr_push_policy_arn` to CI role.

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
│   ├── cloudtrail.tf  # API audit logging
│   ├── secrets.tf
│   ├── iam.tf         # IRSA (ESO, LB Controller), ECR push, RDS connect
│   ├── kms.tf         # Customer-managed keys for Secrets Manager, RDS
│   ├── policies/      # AWS Load Balancer Controller IAM policy
│   ├── backend.hcl.example
│   └── terraform.tfvars.example
├── scripts/
│   └── bootstrap-backend.sh  # Create S3 + DynamoDB for Terraform state
├── deploy/
│   └── external-secrets-aws-example.yaml
├── README.md
├── LICENSE
└── .gitignore
```

---

## Security Defaults

- **Network:** Private subnets for workloads; no 0.0.0.0/0 on RDS; VPC Flow Logs
- **State:** Remote S3 backend + DynamoDB lock (bootstrap via `scripts/bootstrap-backend.sh`)
- **Encryption:** KMS for Secrets Manager and RDS; key rotation enabled
- **IAM:** IRSA for ESO and Load Balancer Controller; ECR push policy for CI
- **Subnets:** Tagged for ALB discovery (`kubernetes.io/role/elb`, `internal-elb`)
- **ECR:** Image scanning on push
- **Tags:** All 8 required tags on resources

---

## Assessment Workflow

To run an AWS Well-Architected assessment of the full TaskForge stack:

1. Open **taskforge-platform-infra** in Cursor (with taskforge-backend and taskforge-security as siblings).
2. Ask: *"Assess the TaskForge stack: read taskforge-backend and taskforge-security, infer the full architecture, produce recommendations, and update this repo with assessments and Terraform patches."*

**Outputs (all in this repo):**
- `docs/assessment/` — Review reports, findings, scorecard
- `terraform/*.tf` — Patches and incremental fixes

The advisor repo (`aws-repo-well-architected-advisor`) is referenced for guidance but is not modified.

---

## Related Repositories

| Repo | Purpose |
|------|---------|
| taskforge-backend | Core API, auth, tasks, notes |
| taskforge-security | CVE scanning, remediation, policy gate |
| aws-repo-well-architected-advisor | Design source; solution brief and target architecture |
