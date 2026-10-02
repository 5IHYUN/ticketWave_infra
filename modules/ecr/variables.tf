variable "environment" {
  type        = string
  description = "Target environment (dev/prod)"
}

variable "project_name" {
  type        = string
  description = "Project name used for standard tags"
}

variable "image_tag_mutability" {
  type        = string
  description = "ECR image tag mutability setting"
  default     = "MUTABLE"
}

variable "max_tagged_image_count" {
  type        = number
  description = "Maximum number of tagged images to keep"
  default     = 30
}

variable "force_delete" {
  type        = bool
  description = "이미지가 남아 있어도 저장소 삭제 허용 (생성·삭제 반복 환경용)"
  default     = false
}
