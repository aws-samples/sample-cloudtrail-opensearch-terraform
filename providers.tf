# =============================================================================
# Provider Configuration
# =============================================================================
# Note: The opensearch provider depends on the domain endpoint and admin role,
# both of which are created by the opensearch-domain module. This creates a
# two-stage apply pattern:
#   1. First apply: creates the domain (target the opensearch_domain module)
#   2. Second apply: creates OpenSearch-provider resources (index, ISM, roles)
#
# See README.md for the recommended deployment workflow.
# =============================================================================

locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "opensearch" {
  url                 = "https://${module.opensearch_domain.endpoint}"
  aws_region          = var.aws_region
  aws_assume_role_arn = module.opensearch_domain.admin_role_arn
  sign_aws_requests   = true
  healthcheck         = false
}
