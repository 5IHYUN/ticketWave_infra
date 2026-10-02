variable "environment" {
  type        = string
  description = "배포 환경 (dev / prod)"
}

variable "is_prod" {
  type        = bool
  default     = false
  description = "운영 환경(prod) 여부 판별값"
}

variable "region" {
  type        = string
  default     = "ap-northeast-2"
  description = "AWS 리전 주소"
}

variable "vpc_id" {
  type        = string
  description = "인프라 VPC ID"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "EKS 퍼블릭 엔드포인트 활성화 여부"
}

variable "bastion_role_arn" {
  type        = string
  description = "배스천 호스트 IAM 역할 ARN"
}

variable "team_member_user_arns" {
  type = map(object({
    arn  = string
    role = string
  }))
  description = "팀원 IAM User ARN 및 역할"
  default     = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "기존 서브넷 ID 연동용"
}

variable "node_desired_size" {
  type        = number
  description = "Managed Node Group 원하는 노드 수"
}

variable "node_min_size" {
  type        = number
  description = "Managed Node Group 최소 노드 수"
}

variable "node_max_size" {
  type        = number
  description = "Managed Node Group 최대 노드 수"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Managed Node Group 인스턴스 타입 리스트"
}

variable "bastion_sg_id" {
  type        = string
  description = "배스천 호스트 보안 그룹 ID"
  default     = null
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM 역할에 적용할 permissions boundary 정책 ARN (없으면 null)"
  default     = null
}

variable "kms_key_administrators" {
  type        = list(string)
  description = "EKS 시크릿 암호화 KMS 키 관리자 IAM ARN 목록 (빈 리스트면 terraform 실행 주체)"
  default     = []
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "CloudWatch로 보낼 EKS 컨트롤 플레인 로그 종류"
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  type        = number
  description = "EKS 컨트롤 플레인 로그 보존 기간(일)"
  default     = 30
}

variable "poster_bucket_name" {
  type        = string
  description = "앱 S3 권한 대상 포스터 버킷 이름 (null이면 team5-<env>-poster-bucket)"
  default     = null
}
