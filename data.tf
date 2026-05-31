# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "opensearch" {
  filter {
    name   = "subnet-id"
    values = var.vpc_subnet_ids
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Derive S3 bucket ARN from bucket name
  cloudtrail_s3_bucket_arn = "arn:${local.partition}:s3:::${var.cloudtrail_s3_bucket_name}"

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )

  # Team role definitions for OpenSearch fine-grained access control
  team_roles = {
    security_ops = {
      description         = "Security Operations - full read, alert management"
      cluster_permissions = ["cluster_monitor", "cluster:admin/opendistro/alerting/*"]
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search", "get"] },
        { index_patterns = [".opendistro-alerting-*"], allowed_actions = ["read", "write", "search", "get", "delete"] }
      ]
    }
    incident_response = {
      description         = "Incident Response - full read for investigation"
      cluster_permissions = ["cluster_monitor"]
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search", "get"] }
      ]
    }
    compliance_auditors = {
      description         = "Compliance - read-only"
      cluster_permissions = []
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search"] }
      ]
    }
    devops = {
      description         = "DevOps - infra metrics and limited CloudTrail"
      cluster_permissions = ["cluster_monitor"]
      index_permissions = [
        { index_patterns = ["infra-metrics-*"], allowed_actions = ["read", "search", "get"] },
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search"] }
      ]
    }
  }

  # CloudTrail tampering events to monitor
  cloudtrail_tampering_events = [
    "StopLogging",
    "DeleteTrail",
    "UpdateTrail",
    "PutEventSelectors"
  ]
}
