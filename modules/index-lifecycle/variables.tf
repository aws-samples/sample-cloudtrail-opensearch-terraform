# -----------------------------------------------------------------------------
# Optional Inputs (all have sensible defaults)
# -----------------------------------------------------------------------------

variable "hot_retention_days" {
  description = "Number of days to keep indices in hot storage"
  type        = number
  default     = 90
}

variable "warm_retention_days" {
  description = "Number of days to keep indices in warm storage"
  type        = number
  default     = 365
}

variable "cold_retention_days" {
  description = "Number of days to keep indices in cold storage (total age before delete)"
  type        = number
  default     = 2555 # ~7 years
}

variable "rollover_size" {
  description = "Maximum index size before rollover (e.g., 50gb)"
  type        = string
  default     = "50gb"
}

variable "rollover_age" {
  description = "Maximum index age before rollover (e.g., 1d)"
  type        = string
  default     = "1d"
}
