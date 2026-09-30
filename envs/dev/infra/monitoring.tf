# envs/dev/infra/monitoring.tf
# 기존 eks.tf / sqs.tf 와 동일 컨벤션: 컴포넌트별 파일 + source 3단계 상위.
# 같은 root(dev/infra)에 있는 module.eks / module.sqs 출력을 그대로 참조.

module "monitoring" {
  source = "../../../modules/monitoring"

  name_prefix                   = "${var.project_name}-${var.environment}" # 예: team5-ticket-dev
  oidc_provider_arn             = module.eks.oidc_provider_arn
  oidc_provider_url             = module.eks.oidc_provider_url # https:// 포함돼도 모듈에서 제거
  booking_queue_arn             = module.sqs.queue_arn         # sqs 모듈 output 이름
  cluster_name                  = module.eks.cluster_name      # CA 태그 조건 + ASG discovery 키
  role_permissions_boundary_arn = var.permissions_boundary_arn

  keda_namespace       = "keda"
  keda_service_account = "keda-operator"
  # default_tags(provider)로 Team/Environment 등은 자동 부착되므로 tags 생략 가능
}

output "keda_irsa_role_arn" {
  value       = module.monitoring.keda_irsa_role_arn
  description = "keda.yaml의 serviceAccount.operator.annotations role-arn에 넣을 값"
}

output "yace_irsa_role_arn" {
  value       = module.monitoring.yace_irsa_role_arn
  description = "yace.yaml의 serviceAccount.annotations role-arn에 넣을 값"
}

output "cluster_autoscaler_irsa_role_arn" {
  value       = module.monitoring.cluster_autoscaler_irsa_role_arn
  description = "cluster-autoscaler.yaml의 rbac.serviceAccount.annotations role-arn에 넣을 값"
}
