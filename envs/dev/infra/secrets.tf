module "secrets" {
  source = "../../../modules/secrets"

  environment    = var.environment
  project_name   = var.project_name
  db_endpoint    = module.database.db_proxy_endpoint
  db_name        = module.database.db_name
  db_username    = module.database.db_username
  db_password    = module.database.db_password
  redis_endpoint = module.elasticache.redis_endpoint
  redis_port     = module.elasticache.redis_port
  sqs_queue_url  = module.sqs.queue_url
  sqs_queue_arn  = module.sqs.queue_arn

  # 검증일 단위 생성·삭제 → 삭제 즉시 같은 이름 재생성 가능해야 함
  recovery_window_in_days = 0
}
