# -----------------------------------------------------------------------------
# ISM Policy - CloudTrail Lifecycle (Hot -> Delete)
# Rollover uses OR conditions: min_primary_shard_size OR min_index_age
# -----------------------------------------------------------------------------

resource "opensearch_ism_policy" "cloudtrail_lifecycle" {
  policy_id = "cloudtrail-lifecycle"
  body = jsonencode({
    policy = {
      description   = "CloudTrail lifecycle - rollover, retain ${var.hot_retention_days}d, delete"
      default_state = "hot"
      ism_template  = [{ index_patterns = ["cloudtrail-*"], priority = 100 }]
      states = [
        {
          name = "hot"
          actions = [{
            rollover = {
              min_primary_shard_size = var.rollover_size
              min_index_age          = var.rollover_age
            }
          }]
          transitions = [{
            state_name = "delete"
            conditions = { min_index_age = "${var.hot_retention_days}d" }
          }]
        },
        {
          name        = "delete"
          actions     = [{ delete = {} }]
          transitions = []
        }
      ]
    }
  })

  depends_on = [aws_opensearch_domain.cloudtrail]
}

# -----------------------------------------------------------------------------
# Optional: Extended ISM Policy with Warm/Cold Tiers
# Uncomment and use instead of the above for 7-year retention scenarios
# See blog post: "Optional: Extending with cold storage for longer retention"
# -----------------------------------------------------------------------------

# resource "opensearch_ism_policy" "cloudtrail_lifecycle_extended" {
#   policy_id = "cloudtrail-lifecycle-extended"
#   body = jsonencode({
#     policy = {
#       description   = "CloudTrail extended lifecycle with warm/cold tiers"
#       default_state = "hot"
#       ism_template  = [{ index_patterns = ["cloudtrail-*"], priority = 100 }]
#       states = [
#         {
#           name = "hot"
#           actions = [{ rollover = { min_primary_shard_size = "30gb", min_index_age = "1d" } }]
#           transitions = [{ state_name = "warm", conditions = { min_index_age = "30d" } }]
#         },
#         {
#           name = "warm"
#           actions = [
#             { warm_migration = {} },
#             { force_merge = { max_num_segments = 1 } }
#           ]
#           transitions = [{ state_name = "cold", conditions = { min_index_age = "365d" } }]
#         },
#         {
#           name = "cold"
#           actions = [{ cold_migration = { timestamp_field = "@timestamp" } }]
#           transitions = [{ state_name = "delete", conditions = { min_index_age = "2555d" } }]
#         },
#         {
#           name        = "delete"
#           actions     = [{ cold_delete = {} }]
#           transitions = []
#         }
#       ]
#     }
#   })
#   depends_on = [aws_opensearch_domain.cloudtrail]
# }
