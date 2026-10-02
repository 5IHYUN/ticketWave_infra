resource "aws_ecr_repository" "app" {
  name                 = "team5-${var.environment}-app"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "team5-${var.environment}-app-ecr"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the most recent tagged images"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = [
            "dev",
            "prod",
            "sha"
          ]
          countType   = "imageCountMoreThan"
          countNumber = var.max_tagged_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
