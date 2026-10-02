variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "team5-ticket"
}

variable "environment" {
  type    = string
  default = "dev"
}

# Network Variables
variable "vpc_cidr" {
  type    = string
  default = "10.5.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.0.0/24", "10.5.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.16.0/20", "10.5.32.0/20"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.48.0/24", "10.5.49.0/24"]
}

variable "enable_multi_nat" {
  type    = bool
  default = false
}

# EKS Variables
variable "cluster_name" {
  type    = string
  default = "team5-dev-eks"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

# RDS Variables
variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "ticketing"
}

variable "db_username" {
  type    = string
  default = "ticketadmin"
}

variable "db_engine_version" {
  type = string
  # MySQL 8.0: RDS 표준 지원 종료(2026-07-31) → 신규 생성 시 유료 Extended Support 자동 가입
  # 8.4 LTS 사용 (로컬 docker-compose mysql 이미지와 동일 버전 유지)
  default = "8.4"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_backup_retention" {
  type    = number
  default = 1
}

# Redis Variables
variable "redis_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 1
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_transit_encryption_enabled" {
  type    = bool
  default = false
}

variable "redis_at_rest_encryption_enabled" {
  type    = bool
  default = true
}

# SQS Variables
variable "sqs_message_retention_seconds" {
  type    = number
  default = 345600
}

variable "sqs_max_receive_count" {
  type    = number
  default = 5
}

# ECR Variables
variable "ecr_image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "ecr_max_tagged_image_count" {
  type    = number
  default = 30
}

# Access Control Variables
variable "team_member_user_arns" {
  type = map(object({
    arn  = string
    role = string
  }))
  default = {}
}

variable "allowed_ssh_cidrs" {
  type    = list(string)
  default = []
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM 역할에 적용할 permissions boundary 정책 ARN (조직 정책상 필요할 때만 지정)"
  default     = null
}

variable "eks_kms_key_administrators" {
  type        = list(string)
  description = "EKS KMS 키 관리자 IAM ARN 목록 (빈 리스트면 terraform 실행 주체)"
  default     = []
}
