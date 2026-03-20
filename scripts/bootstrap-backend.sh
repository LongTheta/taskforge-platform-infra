#!/usr/bin/env bash
# Bootstrap Terraform S3 backend and DynamoDB lock table
# Run once per AWS account/region before first terraform init -backend-config=backend.hcl

set -e

BUCKET="${TF_STATE_BUCKET:-taskforge-terraform-state}"
LOCK_TABLE="${TF_LOCK_TABLE:-taskforge-terraform-lock}"
REGION="${AWS_REGION:-us-east-1}"

echo "Creating S3 bucket: $BUCKET (region: $REGION)"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || \
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" 2>/dev/null || true

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Creating DynamoDB table: $LOCK_TABLE"
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || echo "Table may already exist"

echo "Done. Set in backend.hcl: bucket=$BUCKET, dynamodb_table=$LOCK_TABLE, region=$REGION"
