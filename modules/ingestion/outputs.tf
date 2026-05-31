# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "sqs_queue_url" {
  description = "SQS queue URL for CloudTrail ingestion"
  value       = aws_sqs_queue.cloudtrail_ingestion.url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN for CloudTrail ingestion"
  value       = aws_sqs_queue.cloudtrail_ingestion.arn
}

output "sqs_dlq_url" {
  description = "Dead letter queue URL for failed messages"
  value       = aws_sqs_queue.cloudtrail_ingestion_dlq.url
}

output "osis_pipeline_arn" {
  description = "ARN of the OpenSearch Ingestion pipeline"
  value       = aws_osis_pipeline.cloudtrail.pipeline_arn
}

output "osis_pipeline_role_arn" {
  description = "IAM role ARN used by the OSIS pipeline"
  value       = aws_iam_role.osis_pipeline.arn
}
