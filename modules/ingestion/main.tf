# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  region                   = data.aws_region.current.name
  partition                = data.aws_partition.current.partition
  cloudtrail_s3_bucket_arn = "arn:${local.partition}:s3:::${var.cloudtrail_s3_bucket_name}"
}

# -----------------------------------------------------------------------------
# SQS Queue for CloudTrail Log Ingestion Throttling
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "cloudtrail_ingestion" {
  name                       = "${var.domain_name}-cloudtrail-ingestion"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 20      # Long polling

  # Enable server-side encryption
  sqs_managed_sse_enabled = true

  # Redrive policy for failed messages
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cloudtrail_ingestion_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.domain_name}-cloudtrail-ingestion"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "cloudtrail_ingestion_dlq" {
  name                      = "${var.domain_name}-cloudtrail-ingestion-dlq"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = {
    Name = "${var.domain_name}-cloudtrail-ingestion-dlq"
  }
}

# SQS Queue Policy - Allow S3 to send notifications
resource "aws_sqs_queue_policy" "cloudtrail_ingestion" {
  queue_url = aws_sqs_queue.cloudtrail_ingestion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3Notification"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.cloudtrail_ingestion.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = local.cloudtrail_s3_bucket_arn
        }
      }
    }]
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket Notification to SQS
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "cloudtrail" {
  bucket = var.cloudtrail_s3_bucket_name

  queue {
    queue_arn     = aws_sqs_queue.cloudtrail_ingestion.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "AWSLogs/"
    filter_suffix = ".json.gz"
  }

  depends_on = [aws_sqs_queue_policy.cloudtrail_ingestion]
}

# -----------------------------------------------------------------------------
# IAM Role for OpenSearch Ingestion Pipeline
# -----------------------------------------------------------------------------

resource "aws_iam_role" "osis_pipeline" {
  name = "${var.domain_name}-osis-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "osis-pipelines.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.domain_name}-osis-pipeline"
  }
}

resource "aws_iam_role_policy" "osis_pipeline" {
  name = "osis-pipeline-access"
  role = aws_iam_role.osis_pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadFromS3"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          local.cloudtrail_s3_bucket_arn,
          "${local.cloudtrail_s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "ReadFromSQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.cloudtrail_ingestion.arn
      },
      {
        Sid    = "WriteToOpenSearch"
        Effect = "Allow"
        Action = [
          "es:DescribeDomain",
          "es:ESHttp*"
        ]
        Resource = "${var.opensearch_domain_arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# OpenSearch Ingestion Pipeline (OSIS)
# -----------------------------------------------------------------------------

resource "aws_osis_pipeline" "cloudtrail" {
  pipeline_name               = "${var.domain_name}-ingestion"
  min_units                   = var.osis_min_units
  max_units                   = var.osis_max_units
  pipeline_configuration_body = <<-YAML
    version: "2"
    cloudtrail-pipeline:
      source:
        s3:
          notification_type: "sqs"
          codec:
            json: {}
          sqs:
            queue_url: "${aws_sqs_queue.cloudtrail_ingestion.url}"
            visibility_timeout: "300s"
          compression: "gzip"
          aws:
            region: "${local.region}"
            sts_role_arn: "${aws_iam_role.osis_pipeline.arn}"
      processor:
        - date:
            from_time_received: true
            destination: "@timestamp"
      sink:
        - opensearch:
            hosts:
              - "https://${var.opensearch_domain_endpoint}"
            index: "cloudtrail"
            index_type: "custom"
            document_id_field: "eventID"
            aws:
              region: "${local.region}"
              sts_role_arn: "${aws_iam_role.osis_pipeline.arn}"
  YAML

  vpc_options {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = [aws_security_group.osis_pipeline.id]
  }

  tags = {
    Name = "${var.domain_name}-ingestion"
  }

  depends_on = [
    aws_iam_role_policy.osis_pipeline
  ]
}

# -----------------------------------------------------------------------------
# Security Group for OSIS Pipeline
# -----------------------------------------------------------------------------

resource "aws_security_group" "osis_pipeline" {
  name_prefix = "${var.domain_name}-osis-"
  vpc_id      = var.vpc_id
  description = "Security group for OSIS pipeline ${var.domain_name}"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound for S3, SQS, and OpenSearch"
  }

  tags = {
    Name = "${var.domain_name}-osis-pipeline"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow OSIS pipeline to reach OpenSearch domain
resource "aws_security_group_rule" "opensearch_from_osis" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.osis_pipeline.id
  security_group_id        = var.opensearch_security_group_id
  description              = "Allow HTTPS from OSIS pipeline"
}
