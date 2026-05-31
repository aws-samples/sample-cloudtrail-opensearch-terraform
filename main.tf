# -----------------------------------------------------------------------------
# Security Group for OpenSearch Domain
# -----------------------------------------------------------------------------

resource "aws_security_group" "opensearch" {
  name_prefix = "${var.domain_name}-opensearch-"
  vpc_id      = var.vpc_id
  description = "Security group for OpenSearch domain ${var.domain_name}"

  tags = {
    Name = "${var.domain_name}-opensearch"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "opensearch_https_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.opensearch.id
  description       = "Allow HTTPS from specified CIDR blocks"
}

resource "aws_security_group_rule" "opensearch_https_sg" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.opensearch.id
  description              = "Allow HTTPS from security group ${each.value}"
}

resource "aws_security_group_rule" "opensearch_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.opensearch.id
  description       = "Allow all outbound traffic"
}

# -----------------------------------------------------------------------------
# KMS Key for OpenSearch Encryption at Rest
# -----------------------------------------------------------------------------

resource "aws_kms_key" "opensearch" {
  description             = "KMS key for OpenSearch domain ${var.domain_name} encryption at rest"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.domain_name}-opensearch-kms"
  }
}

resource "aws_kms_alias" "opensearch" {
  name          = "alias/${var.domain_name}-opensearch"
  target_key_id = aws_kms_key.opensearch.key_id
}

# -----------------------------------------------------------------------------
# OpenSearch Domain
# -----------------------------------------------------------------------------

resource "aws_opensearch_domain" "cloudtrail" {
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = var.availability_zone_count
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
    iops        = var.ebs_iops
    throughput  = var.ebs_throughput
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.opensearch.key_id
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false

    # Note: master_user_options is an AWS API field name and cannot be renamed
    master_user_options {
      master_user_arn = aws_iam_role.opensearch_admin.arn
    }
  }

  vpc_options {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = [aws_security_group.opensearch.id]
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "AUDIT_LOGS"
  }

  tags = {
    Name = var.domain_name
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_iam_role.opensearch_admin,
    aws_cloudwatch_log_resource_policy.opensearch
  ]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for OpenSearch Logs
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/domains/${var.domain_name}/logs"
  retention_in_days = 365

  tags = {
    Name = "${var.domain_name}-opensearch-logs"
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${var.domain_name}-opensearch-log-publishing"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOpenSearchLogPublishing"
        Effect    = "Allow"
        Principal = { Service = "es.amazonaws.com" }
        Action = [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.opensearch.arn}:*"
      }
    ]
  })
}
