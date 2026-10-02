module "s3" {
  source = "../../../modules/s3"
  # 버킷 이름은 전 세계 고유 → 옛 팀 버킷(team5-dev-poster-bucket)과 충돌 방지용 새 이름
  # config deployment-patch.yaml AWS_S3_POSTER_BUCKET 값과 일치 필요
  bucket_name   = "ticketwave-dev-poster-5ihyun"
  environment   = var.environment
  force_destroy = true # dev destroy 시 업로드된 포스터 객체 포함 삭제
}
