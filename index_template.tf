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
        number_of_shards                                        = var.number_of_shards
        number_of_replicas                                      = var.number_of_replicas
        "index.refresh_interval"                                = "10s"
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
          errorMessage       = { type = "text" }
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
          requestParameters = { type = "object", enabled = true }
          responseElements  = { type = "object", enabled = true }
        }
      }
    }
  })

  depends_on = [aws_opensearch_domain.cloudtrail]
}
