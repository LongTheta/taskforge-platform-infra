# Principal AWS Platform Engineer — Refactor Complete

## Summary

The Terraform repo has been refactored to enforce security by default, minimize cost, and align with workload-aware architecture. All customer-configurable choices are exposed via variables.

---

## 1. Security by Default

| Change | Before | After |
|--------|--------|-------|
| EKS API endpoint | Public (true) | **Private (false)** — kubectl requires bastion/VPN or explicit enable |
| CloudTrail | On | **Off** — enable when justified |
| Observability alarms | On | **Off** — enable for production |
| ECR tags | MUTABLE | **IMMUTABLE** — prevents overwrite attacks |
| RDS SG egress | 0.0.0.0/0 | **VPC CIDR only** — least privilege |

---

## 2. Cost Minimized by Default

| Change | Before | After |
|--------|--------|-------|
| NAT Gateway | Always 1–2 | **Optional** — `enable_nat_gateway=false` uses VPC endpoints only |
| KMS | Always customer-managed | **Optional** — `use_customer_managed_kms=false` uses AWS-managed |
| CloudTrail | On | Off |
| Alarms | On | Off |

---

## 3. Architecture Workload-Aware

- **NAT**: Disable when ECR, S3, Logs VPC endpoints cover egress
- **KMS**: Enable for compliance; skip for simple dev
- **Multi-AZ**: `rds_multi_az` explicit; not tied to environment name
- **AZ count**: `vpc_az_count` — 1 for dev, 2 for prod

---

## 4. Terraform Structure

- **DRY**: for_each for KMS, ECR, alarms
- **Variables**: All configurable choices in variables.tf
- **Tags**: `merge(var.tags, {...})` in provider default_tags
- **No partial patterns**: All resources fully wired

---

## 5. File-by-File Changes

### eks.tf
- `eks_endpoint_public_access` default false
- `eks_node_group_name` variable

### vpc.tf
- `enable_nat_gateway` — when false, no NAT; private subnets use VPC endpoints only
- NAT route moved to separate `aws_route` resource for conditional creation

### rds.tf
- `kms_key_id` conditional on `use_customer_managed_kms`
- RDS SG egress scoped to `var.vpc_cidr`
- `rds_multi_az`, `rds_backup_window` variables

### kms.tf
- `for_each` conditional: `var.use_customer_managed_kms ? local.kms_keys : {}`
- No KMS keys when false

### ecr.tf
- `ecr_image_tag_mutability` default IMMUTABLE
- `ecr_repository_names` variable

### cloudtrail.tf
- `enable_cloudtrail` default false
- S3 versioning added for log integrity

### observability.tf
- `enable_observability_alarms` default false
- Alarms only when explicitly enabled

### secrets.tf
- `for_each` over `var.secrets_workload_names` — add workloads via tfvars only
- `secrets_workload_placeholders` — per-workload secret keys (sensitive)
- `secrets_workloads_with_db_url` — which workloads receive RDS URL
- `kms_key_id` conditional on `use_customer_managed_kms`

### iam.tf
- ESO policy scoped to `[for s in aws_secretsmanager_secret.workloads : s.arn]`
- `eso_service_account_*`, `lb_controller_service_account_*` variables for IRSA

### Additional variables (no resource edits)
- CloudTrail: `cloudtrail_include_global_service_events`, `cloudtrail_is_multi_region`, `cloudtrail_enable_log_file_validation`
- KMS: `kms_deletion_window_in_days`
- RDS: `rds_cloudwatch_logs_exports`
- ECR: `ecr_scan_on_push`

---

## 6. Variable-Driven Configuration

**Principle**: Customers configure via environment-specific `.tfvars` files only. Resource files consume variables and locals; no edits to `.tf` resource files unless extending the platform.

- Add ECR repos: `ecr_repository_names = ["backend", "security", "api"]`
- Add secrets workloads: `secrets_workload_names`, `secrets_workload_placeholders`, `secrets_workloads_with_db_url`
- Tune CloudTrail, KMS, RDS, ECR, IRSA namespaces — all via variables

---

## 7. Migration for Existing Deployments

If upgrading from a previous version, set in your tfvars to preserve behavior:

```hcl
eks_endpoint_public_access = true   # if you need kubectl from laptop
enable_cloudtrail = true
enable_observability_alarms = true
use_customer_managed_kms = true     # if you had KMS before
```

**Secrets migration**: Replace `secret_backend_secret_key_placeholder` and `secret_security_api_key_placeholder` with:

```hcl
secrets_workload_placeholders = {
  backend = { secret_key = "REPLACE_WITH_OPENSSL_RAND_HEX_32_OUTPUT" }
  security = { api_key = "REPLACE_WITH_STRONG_API_KEY" }
}
```

---

## 8. Why This Is Better

- **Security**: Private-by-default; no public exposure unless justified
- **Cost**: Dev can run ~$50–100/mo cheaper (no NAT, no KMS, no CloudTrail, no alarms)
- **Maintainability**: All choices in variables; no resource edits for config
- **Workload alignment**: Each component justifies itself; simpler alternatives available
