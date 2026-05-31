# -----------------------------------------------------------------------------
# Required Inputs
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Name of the OpenSearch domain (used for resource naming)"
  type        = string
}

# -----------------------------------------------------------------------------
# Optional Inputs
# -----------------------------------------------------------------------------

variable "alert_email_endpoint" {
  description = "Email address to subscribe to the security alerts SNS topic (optional)"
  type        = string
  default     = ""
}
