module "github_oidc" {
  source = "../../../modules/github_oidc"

  environment              = var.environment
  permissions_boundary_arn = var.permissions_boundary_arn
  create_oidc_provider     = true # 새 계정, dev에서만 생성
}
