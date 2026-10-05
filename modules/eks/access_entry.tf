resource "aws_eks_access_entry" "bastion" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.bastion_role_arn
  type          = "STANDARD"

  tags = {
    Name = "team5-${var.environment}-bastion"
  }
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.bastion_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  # principal_arn을 변수로 받아 Terraform이 access entry와의 순서를 모름
  # → entry 생성 전에 association 시도 시 404(ResourceNotFound) → 명시적 의존성
  depends_on = [aws_eks_access_entry.bastion]
}

resource "aws_eks_access_entry" "team_member" {
  for_each = var.team_member_user_arns

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.arn
  type          = "STANDARD"

  tags = {
    Name = "team5-${var.environment}-${each.key}"
  }
}

resource "aws_eks_access_policy_association" "team_member_dev" {
  for_each = var.is_prod == false ? var.team_member_user_arns : {}

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.team_member]
}

resource "aws_eks_access_policy_association" "team_member_prod" {
  for_each = var.is_prod == true ? { for member in var.team_member_user_arns : member.arn => member } : {}

  cluster_name  = module.eks.cluster_name
  principal_arn = each.key

  policy_arn = each.value.role == "admin" ? "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" : (
    each.value.role == "developer" ? "arn:aws:eks::aws:cluster-access-policy/AmazonEKSDeveloperPolicy" :
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  )

  access_scope {
    type       = each.value.role == "admin" ? "cluster" : "namespace"
    namespaces = each.value.role == "admin" ? null : ["default", "app", "monitoring"]
  }

  depends_on = [aws_eks_access_entry.team_member]
}
