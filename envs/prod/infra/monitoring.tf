# envs/prod/infra/monitoring.tf
# 관측성/오토스케일링 애드온이 AWS API를 호출할 때 사용할 IRSA Role을 생성.
# Helm chart 설치 자체는 config repo의 ArgoCD Application이 담당하고,
# 이 파일은 AWS 권한(IAM)만 prod 인프라에 추가한다.

module "monitoring" {
  source = "../../../modules/monitoring"

  name_prefix                   = "${var.project_name}-${var.environment}"
  oidc_provider_arn             = module.eks.oidc_provider_arn
  oidc_provider_url             = module.eks.oidc_provider_url
  booking_queue_arn             = module.sqs.queue_arn
  cluster_name                  = module.eks.cluster_name
  role_permissions_boundary_arn = var.permissions_boundary_arn

  # config repo의 system-addons/overlays/prod/keda.yaml 설정과 일치해야 한다.
  keda_namespace       = "keda"
  keda_service_account = "keda-operator"
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
