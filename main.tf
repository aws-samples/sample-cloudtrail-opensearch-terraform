# =============================================================================
# Root Module — Composing child modules to build the CloudTrail monitoring stack
# =============================================================================
# This file demonstrates how reusable Terraform modules connect together.
# Each module is independently sourceable; this root merely wires them up.
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Core OpenSearch Domain (must exist before OpenSearch provider works)
# -----------------------------------------------------------------------------

module "opensearch_domain" {
  source = "./modules/opensearch-domain"

  domain_name    = var.domain_name
  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.vpc_subnet_ids

  # Optional overrides (defaults are production-ready)
  engine_version             = var.engine_version
  instance_type              = var.instance_type
  instance_count             = var.instance_count
  ebs_volume_size            = var.ebs_volume_size
  ebs_volume_type            = var.ebs_volume_type
  ebs_iops                   = var.ebs_iops
  ebs_throughput             = var.ebs_throughput
  availability_zone_count    = var.availability_zone_count
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  allowed_security_group_ids = var.allowed_security_group_ids
}

# -----------------------------------------------------------------------------
# Stage 2: Ingestion Pipeline (SQS → S3 notifications → OSIS → OpenSearch)
# -----------------------------------------------------------------------------

module "ingestion" {
  source = "./modules/ingestion"

  domain_name               = var.domain_name
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudtrail_s3_bucket_name = var.cloudtrail_s3_bucket_name

  # Wired from opensearch_domain outputs
  opensearch_domain_arn        = module.opensearch_domain.arn
  opensearch_domain_endpoint   = module.opensearch_domain.endpoint
  opensearch_security_group_id = module.opensearch_domain.security_group_id

  # Optional overrides
  osis_min_units = var.osis_min_units
  osis_max_units = var.osis_max_units
}

# -----------------------------------------------------------------------------
# Stage 2: Index Lifecycle (template + ISM policy + bootstrap index)
# Requires the OpenSearch provider — apply after domain exists
# -----------------------------------------------------------------------------

module "index_lifecycle" {
  source = "./modules/index-lifecycle"

  # Optional overrides
  hot_retention_days  = var.hot_retention_days
  warm_retention_days = var.warm_retention_days
  cold_retention_days = var.cold_retention_days
  rollover_size       = var.rollover_size
  rollover_age        = var.rollover_age
}

# -----------------------------------------------------------------------------
# Stage 2: Access Control (roles, role mappings, tenants)
# Requires the OpenSearch provider — apply after domain exists
# -----------------------------------------------------------------------------

module "access_control" {
  source = "./modules/access-control"

  team_role_arns = var.team_role_arns
}

# -----------------------------------------------------------------------------
# Stage 2: Alerting (SNS + monitors + notification channels)
# Requires both the OpenSearch provider and AWS provider
# -----------------------------------------------------------------------------

module "alerting" {
  source = "./modules/alerting"

  domain_name          = var.domain_name
  alert_email_endpoint = var.alert_email_endpoint
}
