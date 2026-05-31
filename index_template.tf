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

  depends_on = [aws_opensearch_domain.cloudtrail]
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
