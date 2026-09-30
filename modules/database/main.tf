# KMS Key for RDS Storage Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS Key for RDS database encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "team5-${var.environment}-rds-key"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/team5-${var.environment}-rds-key"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "team5-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "team5-${var.environment}-db-subnet-group"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier            = "team5-${var.environment}-rds"
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  engine                = "mysql"
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  db_name               = var.db_name
  username              = var.db_username
  password              = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = var.db_multi_az
  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "team5-${var.environment}-rds-final-snapshot"
  backup_retention_period   = var.db_backup_retention

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags = {
    Name        = "team5-${var.environment}-rds"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

# Security Group for RDS Proxy
resource "aws_security_group" "rds_proxy" {
  name        = "team5-${var.environment}-rds-proxy-sg"
  description = "Security group for RDS Proxy allowing EKS nodes and Bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      var.eks_node_sg_id,
      var.bastion_sg_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "team5-${var.environment}-rds-proxy-sg"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

# Security Group for RDS Instance (Only allow traffic from RDS Proxy and Bastion)
resource "aws_security_group" "rds" {
  name        = "team5-${var.environment}-rds-sg"
  description = "Security group for RDS database allowing only EKS workers and Bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      aws_security_group.rds_proxy.id,
      var.bastion_sg_id,
      var.eks_node_sg_id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "team5-${var.environment}-rds-sg"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

# Secrets Manager Secret for RDS Proxy Credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "team5-${var.environment}-db-credentials"
  description             = "Database credentials for RDS Proxy"
  kms_key_id              = aws_kms_key.rds.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "team5-${var.environment}-db-credentials"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username             = var.db_username
    password             = random_password.db.result
    engine               = "mysql"
    host                 = aws_db_instance.main.address
    port                 = 3306
    dbInstanceIdentifier = aws_db_instance.main.identifier
  })
}

# IAM Role and Policy for RDS Proxy to access Secrets Manager
resource "aws_iam_role" "rds_proxy" {
  name                 = "team5-${var.environment}-rds-proxy-role"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "team5-${var.environment}-rds-proxy-role"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name = "team5-${var.environment}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.rds.arn
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.ap-northeast-2.amazonaws.com"
          }
        }
      }
    ]
  })
}

# AWS DB Proxy
resource "aws_db_proxy" "main" {
  name                   = "team5-${var.environment}-rds-proxy"
  debug_logging          = false
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "RDS Proxy Auth using Secrets Manager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
  }

  tags = {
    Name        = "team5-${var.environment}-rds-proxy"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 90
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name          = aws_db_proxy.main.name
  db_instance_identifier = aws_db_instance.main.identifier
  target_group_name      = aws_db_proxy_default_target_group.main.name
}

resource "aws_db_instance" "replica" {
  count = var.environment == "prod" ? 1 : 0

  identifier     = "team5-${var.environment}-rds-replica"
  instance_class = var.db_instance_class
  storage_type   = "gp3"

  replicate_source_db = aws_db_instance.main.identifier

  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  tags = {
    Name        = "team5-${var.environment}-rds-replica"
    Team        = "team5"
    Environment = var.environment
    Project     = var.project_name
    Owner       = "team5"
  }
}
