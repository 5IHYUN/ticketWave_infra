module "eks" {
  source = "../../../modules/eks"

  environment                    = var.environment
  region                         = var.region
  vpc_id                         = module.network.vpc_id
  subnet_ids                     = module.network.private_subnet_ids
  cluster_endpoint_public_access = var.environment == "prod" ? false : true
  node_desired_size              = var.node_desired_size
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
  node_instance_types            = var.node_instance_types
  bastion_role_arn               = module.bastion.bastion_role_arn
  team_member_user_arns          = var.team_member_user_arns
  bastion_sg_id                  = module.bastion.bastion_sg_id
  permissions_boundary_arn       = var.permissions_boundary_arn
  kms_key_administrators         = var.eks_kms_key_administrators
}
