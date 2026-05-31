# =============================================================================
# Root Outputs — Aggregated from child modules
# =============================================================================

# --- OpenSearch Domain ---

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint URL"
  value       = module.opensearch_domain.endpoint
}

output "opensearch_domain_arn" {
  description = "OpenSearch domain ARN"
  value       = module.opensearch_domain.arn
}

output "opensearch_domain_id" {
  description = "OpenSearch domain ID"
  value       = module.opensearch_domain.domain_id
}

output "opensearch_dashboards_endpoint" {
  description = "OpenSearch Dashboards endpoint URL"
  value       = module.opensearch_domain.dashboard_endpoint
}

output "opensearch_security_group_id" {
  description = "Security group ID for the OpenSearch domain"
  value       = module.opensearch_domain.security_group_id
}

output "admin_iam_role_arn" {
  description = "IAM role ARN created as the OpenSearch admin user"
  value       = module.opensearch_domain.admin_role_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for OpenSearch encryption at rest"
  value       = module.opensearch_domain.kms_key_arn
}

# --- Ingestion ---

output "sqs_queue_url" {
  description = "Amazon SQS queue URL for AWS CloudTrail ingestion"
  value       = module.ingestion.sqs_queue_url
}

output "sqs_queue_arn" {
  description = "Amazon SQS queue ARN for AWS CloudTrail ingestion"
  value       = module.ingestion.sqs_queue_arn
}

output "sqs_dlq_url" {
  description = "Dead letter queue URL for failed messages"
  value       = module.ingestion.sqs_dlq_url
}

output "osis_pipeline_arn" {
  description = "ARN of the Amazon OpenSearch Ingestion pipeline"
  value       = module.ingestion.osis_pipeline_arn
}

output "osis_pipeline_role_arn" {
  description = "IAM role ARN used by the OSIS pipeline"
  value       = module.ingestion.osis_pipeline_role_arn
}

# --- Access Control ---

output "opensearch_role_names" {
  description = "Map of created OpenSearch role names"
  value       = module.access_control.role_names
}

output "opensearch_tenant_names" {
  description = "Map of created OpenSearch tenant names"
  value       = module.access_control.tenant_names
}

# --- Alerting ---

output "sns_topic_arn" {
  description = "Amazon SNS topic ARN for security alert notifications"
  value       = module.alerting.sns_topic_arn
}
