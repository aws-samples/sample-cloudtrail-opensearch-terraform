# -----------------------------------------------------------------------------
# SNS Topic for Security Alerts
# -----------------------------------------------------------------------------

resource "aws_kms_key" "sns" {
  description         = "KMS key for SNS topic encryption - ${var.domain_name}"
  enable_key_rotation = true

  tags = {
    Name = "${var.domain_name}-sns-key"
  }
}

resource "aws_kms_alias" "sns" {
  name          = "alias/${var.domain_name}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

resource "aws_sns_topic" "security_alerts" {
  name              = "${var.domain_name}-security-alerts"
  # Note: kms_master_key_id is an AWS API field name and cannot be renamed
  kms_master_key_id = aws_kms_key.sns.arn

  tags = {
    Name = "${var.domain_name}-security-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email_endpoint != "" ? 1 : 0

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_endpoint
}

# -----------------------------------------------------------------------------
# OpenSearch Monitor - CloudTrail Tampering Detection
# -----------------------------------------------------------------------------

resource "opensearch_monitor" "cloudtrail_tampering" {
  body = jsonencode({
    name    = "cloudtrail-tampering-detection"
    type    = "monitor"
    enabled = true
    schedule = {
      period = { interval = 5, unit = "MINUTES" }
    }
    inputs = [{
      search = {
        indices = ["cloudtrail-*"]
        query = {
          size = 0
          query = {
            bool = {
              filter = [
                { range = { "@timestamp" = { gte = "now-5m" } } },
                { terms = { eventName = local.cloudtrail_tampering_events } }
              ]
            }
          }
        }
      }
    }]
    triggers = [{
      name      = "cloudtrail_tamper_alert"
      severity  = "1"
      condition = {
        script = {
          source = "ctx.results[0].hits.total.value > 0"
          lang   = "painless"
        }
      }
      actions = [{
        name             = "notify-security-team"
        destination_id   = opensearch_channel_configuration.sns_alerts.id
        message_template = {
          source = <<-EOF
            ALERT: CloudTrail tampering detected!
            
            Monitor: {{ctx.monitor.name}}
            Trigger: {{ctx.trigger.name}}
            Severity: {{ctx.trigger.severity}}
            Period: {{ctx.periodStart}} to {{ctx.periodEnd}}
            
            Matching events found: {{ctx.results.0.hits.total.value}}
            
            Monitored API calls: ${join(", ", local.cloudtrail_tampering_events)}
            
            Investigate immediately in the OpenSearch Dashboards.
          EOF
        }
        throttle_enabled = true
        throttle = {
          value = 15
          unit  = "MINUTES"
        }
      }]
    }]
  })

  depends_on = [aws_opensearch_domain.cloudtrail]
}

# -----------------------------------------------------------------------------
# Notification Channel - SNS
# -----------------------------------------------------------------------------

resource "opensearch_channel_configuration" "sns_alerts" {
  body = jsonencode({
    config_id   = "sns-security-alerts"
    name        = "SNS Security Alerts"
    description = "Send alerts to SNS topic for security notifications"
    config_type = "sns"
    is_enabled  = true
    config = {
      sns = {
        topic_arn = aws_sns_topic.security_alerts.arn
        role_arn  = aws_iam_role.opensearch_sns.arn
      }
    }
  })

  depends_on = [aws_opensearch_domain.cloudtrail]
}

# -----------------------------------------------------------------------------
# IAM Role for OpenSearch to Publish to SNS
# -----------------------------------------------------------------------------

resource "aws_iam_role" "opensearch_sns" {
  name = "${var.domain_name}-opensearch-sns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "es.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.domain_name}-opensearch-sns"
  }
}

resource "aws_iam_role_policy" "opensearch_sns" {
  name = "sns-publish"
  role = aws_iam_role.opensearch_sns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sns:Publish"
      Effect   = "Allow"
      Resource = aws_sns_topic.security_alerts.arn
    }]
  })
}
