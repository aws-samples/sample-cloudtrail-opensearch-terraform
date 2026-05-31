# =============================================================================
# Root Variables
# =============================================================================
# Only 3 inputs are truly required — everything else has production-ready
# defaults that can be overridden per environment.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Inputs (only 3!)
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID for the OpenSearch domain"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for OpenSearch domain placement (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.vpc_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for multi-AZ deployment."
  }
}

variable "cloudtrail_s3_bucket_name" {
  description = "Name of the existing S3 bucket containing CloudTrail logs"
  type        = string
}

# -----------------------------------------------------------------------------
# General (optional)
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., production, staging, development)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "centralized-cloudtrail-monitoring"
}

# -----------------------------------------------------------------------------
# OpenSearch Domain (optional overrides)
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string
  default     = "cloudtrail-monitoring"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.domain_name))
    error_message = "Domain name must be 3-28 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.13"
}

variable "instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "or1.2xlarge.search"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count >= 3
    error_message = "Instance count must be at least 3 for multi-AZ deployment."
  }
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB per node"
  type        = number
  default     = 500
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "Provisioned IOPS for gp3 volumes"
  type        = number
  default     = 3000
}

variable "ebs_throughput" {
  description = "Provisioned throughput in MiB/s for gp3 volumes"
  type        = number
  default     = 125
}

variable "availability_zone_count" {
  description = "Number of availability zones for the domain"
  type        = number
  default     = 3

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

# -----------------------------------------------------------------------------
# Networking (optional)
# -----------------------------------------------------------------------------

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the OpenSearch domain"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access the OpenSearch domain"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Access Control (optional)
# -----------------------------------------------------------------------------

variable "team_role_arns" {
  description = "Map of team names to their IAM role ARNs for OpenSearch access"
  type        = map(string)
  default     = {}

  # Example:
  # {
  #   security_ops        = "arn:aws:iam::123456789012:role/SecurityOpsRole"
  #   incident_response   = "arn:aws:iam::123456789012:role/IncidentResponseRole"
  #   compliance_auditors = "arn:aws:iam::123456789012:role/ComplianceAuditorsRole"
  #   devops              = "arn:aws:iam::123456789012:role/DevOpsRole"
  # }
}

# -----------------------------------------------------------------------------
# Ingestion (optional)
# -----------------------------------------------------------------------------

variable "osis_min_units" {
  description = "Minimum OCU capacity for the OpenSearch Ingestion pipeline"
  type        = number
  default     = 2

  validation {
    condition     = var.osis_min_units >= 1 && var.osis_min_units <= 96
    error_message = "OSIS min units must be between 1 and 96."
  }
}

variable "osis_max_units" {
  description = "Maximum OCU capacity for the OpenSearch Ingestion pipeline"
  type        = number
  default     = 10

  validation {
    condition     = var.osis_max_units >= 1 && var.osis_max_units <= 96
    error_message = "OSIS max units must be between 1 and 96."
  }
}

# -----------------------------------------------------------------------------
# Alerting (optional)
# -----------------------------------------------------------------------------

variable "alert_email_endpoint" {
  description = "Email address to subscribe to the security alerts SNS topic (optional)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Lifecycle / Retention (optional)
# -----------------------------------------------------------------------------

variable "hot_retention_days" {
  description = "Number of days to keep indices in hot storage"
  type        = number
  default     = 90
}

variable "warm_retention_days" {
  description = "Number of days to keep indices in warm storage"
  type        = number
  default     = 365
}

variable "cold_retention_days" {
  description = "Number of days to keep indices in cold storage (total age before delete)"
  type        = number
  default     = 2555 # ~7 years
}

variable "rollover_size" {
  description = "Maximum index size before rollover (e.g., 50gb)"
  type        = string
  default     = "50gb"
}

variable "rollover_age" {
  description = "Maximum index age before rollover (e.g., 1d)"
  type        = string
  default     = "1d"
}

# -----------------------------------------------------------------------------
# Tags (optional)
# -----------------------------------------------------------------------------

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
