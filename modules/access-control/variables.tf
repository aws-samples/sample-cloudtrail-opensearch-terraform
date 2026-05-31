# -----------------------------------------------------------------------------
# Optional Inputs
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
