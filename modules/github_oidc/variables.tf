variable "environment" {
  type        = string
  description = "Target environment (dev/prod)"
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM 역할에 적용할 permissions boundary 정책 ARN (없으면 null)"
  default     = null
}

variable "github_repositories" {
  type        = list(string)
  description = "OIDC로 이 역할을 assume할 수 있는 GitHub 저장소 (owner/repo)"
  default = [
    "5IHYUN/ticketWave_app",
    "5IHYUN/ticketWave_infra",
    "5IHYUN/ticketWave_config",
  ]
}

variable "create_oidc_provider" {
  type        = bool
  description = "GitHub OIDC provider 생성 여부 (계정에 없을 때 true, 계정당 1곳에서만)"
  default     = false
}
