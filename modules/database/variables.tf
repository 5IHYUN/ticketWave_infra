variable "environment" {
  type        = string
  description = "Target environment (dev/prod)"
}

variable "project_name" {
  type        = string
  description = "Project name used for standard tags"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for DB subnet group (dedicated database subnets)"
}

variable "db_instance_class" {
  type        = string
  description = "Instance class for RDS"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "db_username" {
  type        = string
  description = "Master database username"
}

variable "db_engine_version" {
  type        = string
  description = "MySQL engine version"
  default     = "8.0"
}

variable "db_allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 20
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Maximum autoscaled storage in GB"
  default     = 100
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ failover replica"
}

variable "db_deletion_protection" {
  type        = bool
  description = "Enable RDS deletion protection"
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot during destroy"
}

variable "db_backup_retention" {
  type        = number
  description = "Days of automated backups to retain"
}

variable "eks_node_sg_id" {
  type        = string
  description = "Security group ID of the EKS worker nodes"
}

variable "bastion_sg_id" {
  type        = string
  description = "Security group ID of the Bastion host"
}

variable "permissions_boundary_arn" {
  type        = string
  description = "IAM 역할에 적용할 permissions boundary 정책 ARN (없으면 null)"
  default     = null
}
