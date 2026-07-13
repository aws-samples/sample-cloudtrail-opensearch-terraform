# -----------------------------------------------------------------------------
# OpenSearch Roles (fine-grained access control)
# -----------------------------------------------------------------------------

resource "opensearch_role" "teams" {
  for_each = local.team_roles

  role_name   = each.key
  description = each.value.description

  cluster_permissions = each.value.cluster_permissions

  dynamic "index_permissions" {
    for_each = each.value.index_permissions
    content {
      index_patterns  = index_permissions.value.index_patterns
      allowed_actions = index_permissions.value.allowed_actions
    }
  }

  depends_on = [aws_opensearch_domain.cloudtrail]
}

# -----------------------------------------------------------------------------
# OpenSearch Role Mappings (IAM role to OpenSearch role)
# -----------------------------------------------------------------------------

resource "opensearch_roles_mapping" "teams" {
  for_each = var.team_role_arns

  role_name   = each.key
  description = "IAM role mapping for ${each.key}"

  backend_roles = [each.value]

  depends_on = [opensearch_role.teams]
}

# -----------------------------------------------------------------------------
# OpenSearch Tenants (per-team dashboard isolation)
# -----------------------------------------------------------------------------

resource "opensearch_tenant" "teams" {
  for_each = local.team_roles

  tenant_name = each.key
  description = "Isolated tenant for ${replace(each.key, "_", " ")} team dashboards"

  depends_on = [aws_opensearch_domain.cloudtrail]
}
