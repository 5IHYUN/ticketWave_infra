resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/team5-${var.environment}-cluster/cluster"
  retention_in_days = 30
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "team5-${var.environment}-eks"
  cluster_version = "1.35"

  iam_role_permissions_boundary = var.permissions_boundary_arn
  # 빈 리스트면 terraform을 실행한 IAM 주체가 KMS 키 관리자로 등록된다.
  kms_key_administrators = var.kms_key_administrators

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  authentication_mode = "API_AND_CONFIG_MAP"

  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    eks-pod-identity-agent = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    for k, v in {
      app = {
        name            = "team5-${var.environment}-eks-app-ng"
        use_name_prefix = false

        ami_type                   = "AL2023_x86_64_STANDARD"
        instance_types             = var.node_instance_types
        max_pods                   = 110
        enable_bootstrap_user_data = true

        desired_size = var.node_desired_size
        min_size     = var.node_min_size
        max_size     = var.node_max_size

        # EKS 모듈이 노드그룹 IAM 역할을 직접 생성 및 관리하도록 설정 복구
        iam_role_name                 = "team5-${var.environment}-node-group"
        iam_role_use_name_prefix      = false
        iam_role_permissions_boundary = var.permissions_boundary_arn

        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 50
              volume_type           = "gp3"
              delete_on_termination = true
            }
          }
        }

        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
        }

        labels = {
          role = "app"
        }

        tags = {
          Name        = "team5-${var.environment}-app-node-group"
          Team        = "team5"
          Environment = var.environment
        }
      }
      # runner node group은 prod 환경에서만 생성 (dev 환경은 불필요)
      runner = var.environment == "prod" ? {
        name            = "team5-${var.environment}-eks-runner-ng"
        use_name_prefix = false

        ami_type                   = "AL2023_x86_64_STANDARD"
        instance_types             = var.node_instance_types
        max_pods                   = 110
        enable_bootstrap_user_data = true

        # 평상시 비용을 위해 0대 운영 (부하 테스트 시에만 스케일 아웃)
        desired_size = 0
        min_size     = 0
        max_size     = 10

        create_iam_role = false
        iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/team5-${var.environment}-node-group"

        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 50
              volume_type           = "gp3"
              delete_on_termination = true
            }
          }
        }

        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
        }

        labels = {
          role = "runner"
        }

        taints = [
          {
            key    = "dedicated"
            value  = "runner"
            effect = "NO_SCHEDULE"
          }
        ]

        tags = {
          Name        = "team5-${var.environment}-runner-node-group"
          Team        = "team5"
          Environment = var.environment
        }
      } : null
    } : k => v if v != null
  }

  tags = {
    Name = "team5-${var.environment}-eks"
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster
  ]
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "team5-${var.environment}-ebs-csi"
  role_permissions_boundary_arn = var.permissions_boundary_arn
  policy_name_prefix            = "team5-"
  attach_ebs_csi_policy         = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}


# ---------------------------------------------------------------------------
# Cluster Autoscaler auto-discovery 태그
# ---------------------------------------------------------------------------
# ⚠️ 왜 노드그룹 "tags"가 아니라 별도 aws_autoscaling_group_tag 인가?
#   EKS Managed Node Group의 tags 는 노드그룹 리소스/EC2 인스턴스엔 붙지만,
#   그 노드그룹이 만든 "ASG" 에는 자동 전파되지 않는다.
#   CA는 ASG에 박힌 아래 두 태그를 보고 대상 노드그룹을 발견하므로,
#   ASG에 직접 태그를 박아야 한다.
#
#   - k8s.io/cluster-autoscaler/enabled = true          (이 ASG는 CA 대상)
#   - k8s.io/cluster-autoscaler/<cluster_name> = owned   (이 클러스터 소유)
#

# ---------------------------------------------------------------------------
# 배스천 호스트 → EKS API 서버 보안 그룹 인바운드 허용 (443 포트)
# ---------------------------------------------------------------------------
resource "aws_security_group_rule" "eks_api_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = var.bastion_sg_id
  description              = "Allow Bastion host to communicate with EKS API server"
}
