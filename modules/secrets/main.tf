resource "random_password" "jwt" {
  length           = 48
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "app" {
  name        = "team5/${var.environment}/ticket-app"
  description = "Runtime configuration for the team5 ticketing application"
  # 삭제 후 이름 예약 기간 (0 = 즉시 삭제). dev는 매일 생성·삭제 → 0 필요
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name        = "team5-${var.environment}-ticket-app-secret"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  # JDBC: TLS 필수(sslMode=REQUIRED)
  #   MySQL 8.4 기본 인증(caching_sha2_password)은 평문 연결에서 RSA 공개키 교환 필요
  #   → RDS Proxy 경유 시 "Authentication requires secure connection"으로 접속 실패
  #   → TLS로 연결 (기존 useSSL=false, allowPublicKeyRetrieval=true 제거)
  secret_string = jsonencode({
    SPRING_DATASOURCE_URL         = "jdbc:mysql://${var.db_endpoint}/${var.db_name}?useUnicode=true&sslMode=REQUIRED&serverTimezone=Asia/Seoul&characterEncoding=UTF-8"
    SPRING_DATASOURCE_USERNAME    = var.db_username
    SPRING_DATASOURCE_PASSWORD    = var.db_password
    SPRING_DATASOURCE_REPLICA_URL = var.db_replica_endpoint != null && var.db_replica_endpoint != "" ? "jdbc:mysql://${var.db_replica_endpoint}/${var.db_name}?useUnicode=true&sslMode=REQUIRED&serverTimezone=Asia/Seoul&characterEncoding=UTF-8" : ""
    SPRING_DATA_REDIS_HOST        = var.redis_endpoint
    SPRING_DATA_REDIS_PORT        = tostring(var.redis_port)
    AWS_SQS_BOOKING_QUEUE_URL     = var.sqs_queue_url
    AWS_SQS_BOOKING_QUEUE_ARN     = var.sqs_queue_arn
    APP_S3_CDN_BASE_URL           = var.poster_cdn_base_url
    JWT_SECRET                    = random_password.jwt.result
  })
}
