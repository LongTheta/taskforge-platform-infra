# IAM — Least privilege, IRSA for EKS workloads
# ESO, AWS Load Balancer Controller, ECR push for CI

data "aws_caller_identity" "current" {}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# --- IRSA: External Secrets Operator ---
resource "aws_iam_role" "eso" {
  name = "${var.project}-${var.environment}-eso"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eso_secrets" {
  name   = "secrets-manager-read"
  role   = aws_iam_role.eso.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.backend.arn,
        aws_secretsmanager_secret.security.arn
      ]
    }]
  })
}

# --- IRSA: AWS Load Balancer Controller (creates ALB/NLB from K8s Ingress) ---
resource "aws_iam_role" "lb_controller" {
  name = "${var.project}-${var.environment}-lb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "lb_controller" {
  name   = "aws-load-balancer-controller"
  role   = aws_iam_role.lb_controller.id
  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

# --- IAM Policy: ECR Push for CI ---
resource "aws_iam_policy" "ecr_push" {
  name        = "${var.project}-${var.environment}-ecr-push"
  description = "Allow push to ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetAuthToken"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          aws_ecr_repository.backend.arn,
          aws_ecr_repository.security.arn
        ]
      }
    ]
  })
}

# --- IAM Policy: RDS IAM auth (for migrations) ---
resource "aws_iam_policy" "rds_connect" {
  name        = "${var.project}-${var.environment}-rds-connect"
  description = "Allow connect to RDS via IAM auth"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["rds-db:connect"]
      Resource = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.resource_id}/taskforge_admin"
    }]
  })
}
