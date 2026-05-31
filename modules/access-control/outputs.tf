# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "role_names" {
  description = "Map of created OpenSearch role names"
  value       = { for k, v in opensearch_role.teams : k => v.role_name }
}

output "tenant_names" {
  description = "Map of created OpenSearch tenant names"
  value       = { for k, v in opensearch_tenant.teams : k => v.tenant_name }
}
