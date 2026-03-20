# TaskForge Platform Terraform — File-by-File Review

## 1. eks.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Security | EKS cluster/node IAM roles lack tags (default_tags apply but explicit Name helps) |
| Cost | Scaling hardcoded `var.environment == "prod"`; no variable for desired/max/min |
| Deployability | EKS version hardcoded 1.28; node_group_name "default" may conflict on recreate |
| Maintainability | Scaling logic inline; could be variables |

### Recommended Changes
- Add `eks_desired_size`, `eks_max_size`, `eks_min_size` variables
- Add `eks_version` variable
- Add explicit tags to IAM roles for consistency
- Use `var.eks_node_instance_types` (already exists) — consider t3.small for dev

### Why Improved Version Is Better
- **Cost:** Dev can run 1 node, prod 2–4; instance type configurable
- **Deployability:** Version upgrades via variable; no code change
- **Maintainability:** Scaling logic in tfvars per environment

### Implemented
- `var.eks_desired_size`, `eks_min_size`, `eks_max_size`, `eks_version`
- Removed hardcoded `var.environment == "prod"` scaling

---

## 2. vpc.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Cost | **2 NAT gateways** (~$64/month + data) — dev rarely needs multi-AZ NAT |
| Cost | Flow log retention 14 days hardcoded |
| Over-engineering | Always 2 AZs; single NAT could suffice for dev |
| Missing | VPC, subnets lack explicit Name tag (default_tags apply) |
| IAM | Flow logs policy: CreateLogGroup on specific resource — correct; but Describe* could be scoped |

### Recommended Changes
- Add `nat_gateway_count` (1 for dev, 2 for prod) — single NAT in one AZ
- Add `vpc_flow_log_retention_days` variable
- Add `vpc_az_count` variable (1 for minimal dev, 2 for prod)
- Route private subnets to single NAT when count=1

### Why Improved Version Is Better
- **Cost:** Single NAT saves ~$32/month for dev; flow log retention configurable
- **Simplicity:** 1 AZ dev topology valid for many workloads
- **Flexibility:** Prod keeps 2 NAT for HA

### Implemented
- `var.nat_gateway_count`, `vpc_az_count`, `vpc_flow_log_retention_days`
- Private route tables use `min(count.index, nat_gateway_count - 1)` for single-NAT routing

---

## 3. rds.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Security | **No `skip_final_snapshot`** — default false; explicit for prod safety |
| Cost | `backup_retention_period = 7` always — dev could use 0 |
| Deployability | `db_name`, `username` hardcoded "taskforge", "taskforge_admin" |
| Deployability | `engine_version` "15" — use full version "15.4" for reproducibility |
| Deployability | `allocated_storage` hardcoded 20 |

### Recommended Changes
- Add `rds_skip_final_snapshot` (false prod, true dev)
- Add `rds_backup_retention_period` variable
- Add `rds_db_name`, `rds_username` variables
- Add `rds_allocated_storage`, `rds_engine_version` variables

### Why Improved Version Is Better
- **Security:** Explicit skip_final_snapshot prevents accidental data loss on destroy
- **Cost:** Dev backup_retention 0 saves storage
- **Deployability:** All RDS params in variables; no code change for env differences

### Implemented
- `var.rds_db_name`, `rds_username`, `rds_allocated_storage`, `rds_engine_version`
- `var.rds_backup_retention_period`, `rds_skip_final_snapshot`
- `final_snapshot_identifier` when skip_final_snapshot=false

---

## 4. iam.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Security | ECR GetAuthorizationToken `Resource = "*"` — required per AWS; document |
| Deployability | LB controller policy in external file — ensure file exists; consider inline for single-file deploy |
| Missing | IAM roles lack explicit tags (default_tags apply) |

### Recommended Changes
- Add comment for GetAuthorizationToken * requirement
- IAM roles: default_tags sufficient; optional explicit Name for clarity

### Why Improved Version Is Better
- **Clarity:** Document why * is required; avoids "overly permissive" flag in reviews

### Implemented
- Comment for GetAuthorizationToken Resource="*"
- ECR policy uses `for r in aws_ecr_repository.repos`
- RDS connect uses `var.rds_username`

---

## 5. kms.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Duplication | Two nearly identical key blocks — for_each |
| Security | Service principal: add `kms:DescribeKey` for key validation |
| Missing | KMS keys lack tags |

### Recommended Changes
- Refactor with for_each over { secrets, rds }
- Add kms:DescribeKey to service statement
- Add tags to keys

### Why Improved Version Is Better
- **Maintainability:** Add new key by extending map
- **Security:** DescribeKey helps services validate key
- **Cost allocation:** Tags on keys

### Implemented
- for_each over { secrets, rds }; `aws_kms_key.keys["rds"]`, `keys["secrets"]`
- Added kms:DescribeKey to service statement

---

## 6. ecr.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Hardcoded | "taskforge-backend", "taskforge-security" — should use var.project |
| Duplication | Identical lifecycle policy for both repos |
| Security | MUTABLE for both — prod might want IMMUTABLE |
| Missing | No encryption_config (ECR uses AES256 by default; KMS optional) |

### Recommended Changes
- Use `var.project` for repo names: `${var.project}-backend`, `${var.project}-security`
- for_each over repos; single lifecycle policy via local
- Add `ecr_image_tag_mutability` variable (MUTABLE dev, IMMUTABLE prod)

### Why Improved Version Is Better
- **Reusability:** Same Terraform for other projects
- **DRY:** One lifecycle definition
- **Security:** Immutable tags for prod prevent overwrite

### Implemented
- for_each over `local.ecr_repos` (backend, security)
- Repo names: `${var.project}-${each.key}`
- `var.ecr_image_tag_mutability`, `ecr_lifecycle_max_image_count`

---

## 7. cloudtrail.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Cost | Retention 90 days hardcoded — could be variable |
| Security | AES256 — acceptable; KMS optional for compliance |
| Missing | CloudTrail log file validation enabled — good |

### Recommended Changes
- Add `cloudtrail_log_retention_days` variable
- Consider KMS for CloudTrail bucket (optional; adds cost)

### Why Improved Version Is Better
- **Cost:** Shorter retention for dev saves S3
- **Flexibility:** Compliance may require 365 days

### Implemented
- `var.cloudtrail_log_retention_days`

---

## 8. observability.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Duplication | Three alarm blocks with same structure — for_each |
| Config | period 300, thresholds hardcoded |
| Missing | No SNS topic for alarm actions — alarms fire but no notification |

### Recommended Changes
- for_each over alarm definitions
- Add `alarm_period_seconds`, `rds_cpu_threshold` variables
- Optional: SNS topic + subscription for alerting (adds complexity)

### Why Improved Version Is Better
- **Maintainability:** Add alarm by extending map
- **Flexibility:** Thresholds configurable per environment

### Implemented
- for_each over `alarm_definitions`
- `var.alarm_period_seconds`, `rds_cpu_alarm_threshold`, `rds_connections_alarm_threshold`

---

## 9. secrets.tf

### Weaknesses
| Type | Issue |
|------|-------|
| Deployability | db_name, username hardcoded in secret URL |
| Security | var.db_password in secret — acceptable for bootstrap; document rotation |
| Missing | Placeholder "REPLACE_WITH_*" — document in README |

### Recommended Changes
- Use variables for db_name, username in secret URL
- Add comment: rotate db_password after first apply; use Secrets Manager rotation

### Why Improved Version Is Better
- **Deployability:** Matches RDS variables
- **Security:** Clear rotation guidance

### Implemented
- Secret URL uses `var.rds_db_name`
