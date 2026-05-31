# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "endpoint" {
  description = "OpenSearch domain endpoint URL"
  value       = aws_opensearch_domain.cloudtrail.endpoint
}

output "arn" {
  description = "OpenSearch domain ARN"
  value       = aws_opensearch_domain.cloudtrail.arn
}

output "domain_id" {
  description = "OpenSearch domain ID"
  value       = aws_opensearch_domain.cloudtrail.domain_id
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint URL"
  value       = aws_opensearch_domain.cloudtrail.dashboard_endpoint
}

output "security_group_id" {
  description = "Security group ID for the OpenSearch domain"
  value       = aws_security_group.opensearch.id
}

output "admin_role_arn" {
  description = "IAM role ARN created as the OpenSearch admin user"
  value       = aws_iam_role.opensearch_admin.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for OpenSearch encryption at rest"
  value       = aws_kms_key.opensearch.arn
}
