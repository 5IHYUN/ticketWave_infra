data "aws_caller_identity" "current" {}

# =====================================
# EKS Pod Identity Common Assume Role Doc
# =====================================
data "aws_iam_policy_document" "eks_pod_identity_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# =====================================
# 1. AWS Load Balancer Controller (LBC) IAM
# =====================================
resource "aws_iam_role" "lbc" {
  name                 = "team5-${var.environment}-lbc-role"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.eks_pod_identity_assume.json

  tags = {
    Name = "team5-${var.environment}-lbc-role"
    Team = "team5"
  }
}

resource "aws_iam_policy" "lbc" {
  name        = "team5-${var.environment}-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:CreateServiceLinkedRole"
        ]

        Resource = "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing"
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolDetails",
          "ec2:GetTransitGatewayPrefixListReferences",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSOPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeTags"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:CreateTags"
        ]

        Resource = "arn:aws:ec2:*:*:security-group/*"
      },
      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:SetWebAcl"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]

        Resource = [
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*",
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/*/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]

        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn
}

# =====================================
# 2. External Secrets Operator (ESO) IAM
# =====================================
resource "aws_iam_role" "eso" {
  name                 = "team5-${var.environment}-eso-role"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.eks_pod_identity_assume.json

  tags = {
    Name = "team5-${var.environment}-eso-role"
    Team = "team5"
  }
}

resource "aws_iam_policy" "eso" {
  name        = "team5-${var.environment}-eso-policy"
  description = "Hardened IAM policy for ESO restricted to team5 secrets"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]

        # 실제 Secrets Manager 이름: team5/dev/ticket-app
        # 따라서 ARN 패턴은 team5/${var.environment}/* 형태로 맞춰야 함
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:team5/${var.environment}/*"
      },
      {
        Effect = "Allow"

        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]

        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/team5/${var.environment}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso.arn
}

# =====================================
# 3. ExternalDNS IAM
# =====================================
resource "aws_iam_role" "external_dns" {
  name                 = "team5-${var.environment}-external-dns-role"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.eks_pod_identity_assume.json

  tags = {
    Name = "team5-${var.environment}-external-dns-role"
    Team = "team5"
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "team5-${var.environment}-external-dns-policy"
  description = "Hardened IAM policy for ExternalDNS Route53 access"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "route53:ChangeResourceRecordSets"
        ]

        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"

        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn
}

# =====================================
# 4. Cluster Autoscaler IAM Role (IRSA)
# =====================================
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "team5-${var.environment}-cluster-autoscaler"
  role_permissions_boundary_arn    = var.permissions_boundary_arn
  policy_name_prefix               = "team5-"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

# =====================================
# 5. Ticket Service & Booking Worker (SQS access) IAM
# =====================================
resource "aws_iam_role" "app_sqs" {
  name                 = "team5-${var.environment}-app-sqs-role"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.eks_pod_identity_assume.json

  tags = {
    Name = "team5-${var.environment}-app-sqs-role"
    Team = "team5"
  }
}

resource "aws_iam_policy" "app_sqs" {
  name        = "team5-${var.environment}-app-sqs-policy"
  description = "IAM policy for application SQS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::team5-${var.environment}-poster-bucket",
          "arn:aws:s3:::team5-${var.environment}-poster-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_sqs" {
  role       = aws_iam_role.app_sqs.name
  policy_arn = aws_iam_policy.app_sqs.arn
}

resource "aws_eks_pod_identity_association" "ticket_service" {
  cluster_name    = module.eks.cluster_name
  namespace       = "ticketing"
  service_account = "ticket-service"
  role_arn        = aws_iam_role.app_sqs.arn
}

resource "aws_eks_pod_identity_association" "booking_worker" {
  cluster_name    = module.eks.cluster_name
  namespace       = "ticketing"
  service_account = "booking-worker"
  role_arn        = aws_iam_role.app_sqs.arn
}
