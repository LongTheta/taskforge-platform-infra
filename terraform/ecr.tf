# ECR — Container registry for backend and security workloads
# for_each removes duplication; use var.project for repo names

locals {
  ecr_repos = toset(var.ecr_repository_names)
}

resource "aws_ecr_repository" "repos" {
  for_each = local.ecr_repos

  name                 = "${var.project}-${each.key}"
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "repos" {
  for_each = local.ecr_repos

  repository = aws_ecr_repository.repos[each.key].name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.ecr_lifecycle_max_image_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_lifecycle_max_image_count
      }
      action = { type = "expire" }
    }]
  })
}
