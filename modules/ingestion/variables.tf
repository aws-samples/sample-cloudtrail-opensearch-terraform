# -----------------------------------------------------------------------------
# Required Inputs
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Name of the OpenSearch domain (used for resource naming)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the OSIS pipeline security group"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for the OSIS pipeline placement"
  type        = list(string)
}

variable "cloudtrail_s3_bucket_name" {
  description = "Name of the existing S3 bucket containing CloudTrail logs"
  type        = string
}

variable "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain (for IAM policy)"
  type        = string
}

variable "opensearch_domain_endpoint" {
  description = "Endpoint of the OpenSearch domain (for OSIS pipeline sink)"
  type        = string
}

variable "opensearch_security_group_id" {
  description = "Security group ID of the OpenSearch domain (to add ingress rule)"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Inputs
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
