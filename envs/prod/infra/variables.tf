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
  default = "prod"
}

# Network Variables
variable "vpc_cidr" {
  type    = string
  default = "10.5.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.64.0/24", "10.5.65.0/24", "10.5.66.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.80.0/20", "10.5.96.0/20", "10.5.112.0/20"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.5.128.0/24", "10.5.129.0/24", "10.5.130.0/24"]
}

variable "enable_multi_nat" {
  type    = bool
  default = true
}

# EKS Variables
variable "cluster_name" {
  type    = string
  default = "team5-prod-eks"
}

variable "node_desired_size" {
  type    = number
  default = 6
}

variable "node_min_size" {
  type    = number
  default = 4
}

variable "node_max_size" {
  type    = number
  default = 15
}

variable "node_instance_types" {
  type    = list(string)
  default = ["c6i.xlarge"]
}

# RDS Variables
variable "db_instance_class" {
  type    = string
  default = "db.m6i.large"
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
  type    = string
  default = "8.0"
}

variable "db_allocated_storage" {
  type    = number
  default = 100
}

variable "db_max_allocated_storage" {
  type    = number
  default = 500
}

variable "db_multi_az" {
  type    = bool
  default = true
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "db_backup_retention" {
  type    = number
  default = 7
}

# Redis Variables
variable "redis_node_type" {
  type    = string
  default = "cache.m7g.large"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 2
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
  default = "IMMUTABLE"
}

variable "ecr_max_tagged_image_count" {
  type    = number
  default = 50
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

variable "waf_rate_limit" {
  type    = number
  default = 2000
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
