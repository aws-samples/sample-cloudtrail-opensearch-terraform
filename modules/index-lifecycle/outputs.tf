# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "index_template_name" {
  description = "Name of the created index template"
  value       = opensearch_index_template.cloudtrail.name
}

output "ism_policy_id" {
  description = "ID of the ISM lifecycle policy"
  value       = opensearch_ism_policy.cloudtrail_lifecycle.policy_id
}

output "initial_index_name" {
  description = "Name of the bootstrap index"
  value       = opensearch_index.cloudtrail_initial.name
}
