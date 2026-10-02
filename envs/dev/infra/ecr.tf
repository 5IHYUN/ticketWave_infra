module "ecr" {
  source = "../../../modules/ecr"

  environment            = var.environment
  project_name           = var.project_name
  image_tag_mutability   = var.ecr_image_tag_mutability
  max_tagged_image_count = var.ecr_max_tagged_image_count
  force_delete           = true # dev destroy 시 이미지 포함 삭제
}
