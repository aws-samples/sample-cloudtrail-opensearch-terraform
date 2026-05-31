# -----------------------------------------------------------------------------
# Primary Admin IAM Role for OpenSearch
# -----------------------------------------------------------------------------

resource "aws_iam_role" "opensearch_admin" {
  name = "${var.domain_name}-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAssumeRole"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name = "${var.domain_name}-admin"
  }
}

resource "aws_iam_role_policy" "opensearch_admin" {
  name = "opensearch-admin-access"
  role = aws_iam_role.opensearch_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OpenSearchDomainAccess"
        Effect = "Allow"
        Action = [
          "es:ESHttp*",
          "es:DescribeDomain",
          "es:DescribeDomainConfig",
          "es:ListTags"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:es:${local.region}:${local.account_id}:domain/${var.domain_name}/*"
      }
    ]
  })
}
