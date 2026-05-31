# -----------------------------------------------------------------------------
# OpenSearch Index Template for CloudTrail
# -----------------------------------------------------------------------------

resource "opensearch_index_template" "cloudtrail" {
  name = "cloudtrail-template"
  body = jsonencode({
    index_patterns = ["cloudtrail-*"]
    priority       = 100
    template = {
      settings = {
        number_of_shards   = 3
        number_of_replicas = 1
        "index.refresh_interval"                                = "30s"
        "index.translog.durability"                             = "async"
        "index.translog.sync_interval"                          = "30s"
        "plugins.index_state_management.rollover_alias"         = "cloudtrail"
      }
      mappings = {
        properties = {
          "@timestamp"       = { type = "date" }
          eventSource        = { type = "keyword" }
          eventName          = { type = "keyword" }
          awsRegion          = { type = "keyword" }
          sourceIPAddress    = { type = "ip" }
          errorCode          = { type = "keyword" }
          errorMessage       = { type = "text", fields = { keyword = { type = "keyword", ignore_above = 256 } } }
          recipientAccountId = { type = "keyword" }
          userIdentity = {
            properties = {
              type      = { type = "keyword" }
              arn       = { type = "keyword" }
              accountId = { type = "keyword" }
              userName  = { type = "keyword" }
              sessionContext = {
                properties = {
                  sessionIssuer = {
                    properties = {
                      type     = { type = "keyword" }
                      arn      = { type = "keyword" }
                      userName = { type = "keyword" }
                    }
                  }
                }
              }
            }
          }
          requestParameters = { type = "flat_object" }
          responseElements  = { type = "flat_object" }
        }
      }
    }
  })
}

# -----------------------------------------------------------------------------
# Initial Rollover Alias (bootstrap)
# -----------------------------------------------------------------------------

resource "opensearch_index" "cloudtrail_initial" {
  name = "cloudtrail-000001"
  body = jsonencode({
    aliases = {
      cloudtrail = {
        is_write_index = true
      }
    }
  })

  depends_on = [opensearch_index_template.cloudtrail]
}

# -----------------------------------------------------------------------------
# ISM Policy - CloudTrail Retention with Tiered Storage
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
}
