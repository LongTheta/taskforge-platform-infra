# Terraform Apply Order

How dependencies are ordered to avoid apply errors. Terraform infers most dependencies from resource references; we add explicit `depends_on` where needed.

---

## Dependency Graph (Simplified)

```
Phase 1 (Foundation)
  data.aws_availability_zones
  data.aws_caller_identity
  data.tls_certificate (after EKS exists)
       │
       ▼
  aws_vpc.main
       │
       ├──► subnets, IGW, NAT, route tables
       ├──► aws_security_group.rds
       ├──► aws_security_group.vpc_endpoints (if enable_vpc_endpoints)
       └──► flow logs (CloudWatch log group, IAM role)

Phase 2 (Data & Secrets)
  aws_kms_key (secrets, rds)
  aws_db_subnet_group
  aws_db_instance
  aws_secretsmanager_secret
  aws_ecr_repository

Phase 3 (EKS)
  aws_iam_role (eks_cluster, eks_node)
  aws_eks_cluster
  aws_eks_node_group
  aws_iam_openid_connect_provider
  aws_iam_role (eso, lb_controller, ecr_push)

Phase 4 (Observability & Audit)
  aws_s3_bucket.cloudtrail
  aws_s3_bucket_server_side_encryption_configuration
  aws_s3_bucket_policy.cloudtrail  ← must complete before CloudTrail
  aws_cloudtrail.main              ← depends_on bucket policy
  aws_cloudwatch_metric_alarm       ← depends_on RDS

Phase 5 (VPC Endpoints)
  aws_vpc_endpoint.s3              ← needs route tables
  aws_vpc_endpoint.ecr_api/dkr/logs ← need security group
```

---

## Explicit depends_on

| Resource | depends_on | Reason |
|----------|------------|--------|
| `aws_cloudtrail.main` | `aws_s3_bucket_policy.cloudtrail` | CloudTrail validates bucket policy before creating trail; policy must be applied first |
| `aws_cloudwatch_metric_alarm.rds_*` | (implicit via `aws_db_instance.main`) | Alarms reference RDS instance ID |

---

## Phased Apply (Optional)

For first-time or large applies, you can run in phases:

```bash
# Phase 1: VPC and networking
terraform apply -target=aws_vpc.main -target=aws_subnet.public -target=aws_subnet.private \
  -target=aws_nat_gateway.main -target=aws_route_table.private -target=aws_flow_log.main

# Phase 2: KMS, RDS, ECR, Secrets
terraform apply -target=aws_kms_key.secrets -target=aws_kms_key.rds \
  -target=aws_db_instance.main -target=aws_ecr_repository.backend -target=aws_ecr_repository.security

# Phase 3: EKS
terraform apply -target=aws_eks_cluster.main -target=aws_eks_node_group.main

# Phase 4: Remainder
terraform apply
```

**Default:** A single `terraform apply` works; Terraform orders resources by dependency.

---

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `InsufficientS3BucketPolicyException` | CloudTrail created before bucket policy applied | `depends_on = [aws_s3_bucket_policy.cloudtrail]` on CloudTrail |
| `InvalidParameterValue: Log group does not exist` | Flow log before log group | Log group and IAM role are in vpc.tf; flow log references them |
| `InvalidSubnetID` on VPC endpoint | Subnets not ready | Endpoints reference `aws_subnet.private[*].id`; implicit dependency |
