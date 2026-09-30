module "github_oidc" {
  source = "../../../modules/github_oidc"

  environment              = var.environment
  permissions_boundary_arn = var.permissions_boundary_arn
}
