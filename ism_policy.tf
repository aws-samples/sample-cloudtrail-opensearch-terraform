# -----------------------------------------------------------------------------
# ISM Policy - CloudTrail 7-Year Retention with Tiered Storage
# -----------------------------------------------------------------------------

resource "opensearch_ism_policy" "cloudtrail_lifecycle" {
  policy_id = "cloudtrail-lifecycle"
  body = jsonencode({
    policy = {
      description   = "CloudTrail ${var.cold_retention_days / 365}-year retention with tiered storage"
      default_state = "hot"
      ism_template  = [{ index_patterns = ["cloudtrail-*"], priority = 100 }]
      states = [
        {
          name = "hot"
          actions = [{
            rollover = {
              min_size      = var.rollover_size
              min_index_age = var.rollover_age
            }
          }]
          transitions = [{
            state_name = "warm"
            conditions = { min_index_age = "${var.hot_retention_days}d" }
          }]
        },
        {
          name = "warm"
          actions = [
            { warm_migration = {} },
            { force_merge = { max_num_segments = 1 } },
            { replica_count = { number_of_replicas = 0 } }
          ]
          transitions = [{
            state_name = "cold"
            conditions = { min_index_age = "${var.warm_retention_days}d" }
          }]
        },
        {
          name = "cold"
          actions = [{
            cold_migration = { timestamp_field = "@timestamp" }
          }]
          transitions = [{
            state_name = "delete"
            conditions = { min_index_age = "${var.cold_retention_days}d" }
          }]
        },
        {
          name        = "delete"
          actions     = [{ cold_delete = {} }]
          transitions = []
        }
      ]
    }
  })

  depends_on = [aws_opensearch_domain.cloudtrail]
}
