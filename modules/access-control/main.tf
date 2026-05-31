# -----------------------------------------------------------------------------
# Locals - Team Role Definitions
# -----------------------------------------------------------------------------

locals {
  team_roles = {
    security_ops = {
      description         = "Security Operations - full read, alert management"
      cluster_permissions = ["cluster_monitor", "cluster:admin/opendistro/alerting/*"]
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search", "get"] },
        { index_patterns = [".opendistro-alerting-*"], allowed_actions = ["read", "write", "search", "get", "delete"] }
      ]
    }
    incident_response = {
      description         = "Incident Response - full read for investigation"
      cluster_permissions = ["cluster_monitor"]
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search", "get"] }
      ]
    }
    compliance_auditors = {
      description         = "Compliance - read-only"
      cluster_permissions = []
      index_permissions = [
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search"] }
      ]
    }
    devops = {
      description         = "DevOps - infra metrics and limited CloudTrail"
      cluster_permissions = ["cluster_monitor"]
      index_permissions = [
        { index_patterns = ["infra-metrics-*"], allowed_actions = ["read", "search", "get"] },
        { index_patterns = ["cloudtrail-*"], allowed_actions = ["read", "search"] }
      ]
    }
  }
}

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
}
