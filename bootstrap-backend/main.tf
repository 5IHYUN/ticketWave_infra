# Terraform state 저장용 S3 버킷 (최초 1회 생성, 로컬 state)
# - 버킷 이름은 전 세계 고유 → 새 계정용 이름 (옛 팀 버킷 tfstate-lionkdt5-team5 대체)
# - envs/*/backend.tf의 bucket 값과 일치 필요
# - 잠금: S3 네이티브 잠금(use_lockfile) 사용 → DynamoDB 테이블 불필요
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "ticketwave-tfstate-5ihyun"

  # state 유실 방지 (dev 리소스를 destroy해도 이 버킷은 유지)
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "ticketwave"
    Purpose = "tfstate"
  }
}

# state 덮어쓰기·삭제 시 이전 버전 복구용
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# state에 DB 비밀번호 등 민감 값 포함 → 공개 접근 전면 차단
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
