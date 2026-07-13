provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "opensearch" {
  url                = "https://${aws_opensearch_domain.cloudtrail.endpoint}"
  aws_region         = var.aws_region
  aws_assume_role_arn = aws_iam_role.opensearch_admin.arn
  sign_aws_requests  = true
  healthcheck        = false
}
