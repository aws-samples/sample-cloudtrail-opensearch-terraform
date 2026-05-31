# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "SNS topic ARN for security alert notifications"
  value       = aws_sns_topic.security_alerts.arn
}

output "sns_kms_key_arn" {
  description = "KMS key ARN used for SNS topic encryption"
  value       = aws_kms_key.sns.arn
}
