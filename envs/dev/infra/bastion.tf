module "bastion" {
  source = "../../../modules/bastion"

  environment              = var.environment
  vpc_id                   = module.network.vpc_id
  public_subnet_id         = module.network.public_subnet_ids[0]
  allowed_ssh_cidrs        = var.allowed_ssh_cidrs
  permissions_boundary_arn = var.permissions_boundary_arn
}
