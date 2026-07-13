# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint URL"
  value       = aws_opensearch_domain.cloudtrail.endpoint
}

output "opensearch_domain_arn" {
  description = "OpenSearch domain ARN"
  value       = aws_opensearch_domain.cloudtrail.arn
}

output "opensearch_domain_id" {
  description = "OpenSearch domain ID"
  value       = aws_opensearch_domain.cloudtrail.domain_id
}

output "opensearch_dashboards_endpoint" {
  description = "OpenSearch Dashboards endpoint URL"
  value       = aws_opensearch_domain.cloudtrail.dashboard_endpoint
}

output "opensearch_security_group_id" {
  description = "Security group ID for the OpenSearch domain"
  value       = aws_security_group.opensearch.id
}

output "admin_iam_role_arn" {
  description = "IAM role ARN created as the OpenSearch admin user"
  value       = aws_iam_role.opensearch_admin.arn
}

output "sns_topic_arn" {
  description = "Amazon SNS topic ARN for security alert notifications"
  value       = aws_sns_topic.security_alerts.arn
}

output "sqs_queue_url" {
  description = "Amazon SQS queue URL for AWS CloudTrail ingestion"
  value       = aws_sqs_queue.cloudtrail_ingestion.url
}

output "sqs_queue_arn" {
  description = "Amazon SQS queue ARN for AWS CloudTrail ingestion"
  value       = aws_sqs_queue.cloudtrail_ingestion.arn
}

output "sqs_dlq_url" {
  description = "Dead letter queue URL for failed messages"
  value       = aws_sqs_queue.cloudtrail_ingestion_dlq.url
}

output "osis_pipeline_arn" {
  description = "ARN of the Amazon OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.cloudtrail.pipeline_arn
}

output "osis_pipeline_role_arn" {
  description = "IAM role ARN used by the OSIS pipeline"
  value       = aws_iam_role.osis_pipeline.arn
}

output "opensearch_role_names" {
  description = "Map of created OpenSearch role names"
  value       = { for k, v in opensearch_role.teams : k => v.role_name }
}

output "opensearch_tenant_names" {
  description = "Map of created OpenSearch tenant names"
  value       = { for k, v in opensearch_tenant.teams : k => v.tenant_name }
}

output "kms_key_arn" {
  description = "KMS key ARN used for OpenSearch encryption at rest"
  value       = aws_kms_key.opensearch.arn
}
