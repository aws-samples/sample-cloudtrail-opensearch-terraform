# -----------------------------------------------------------------------------
# Required Inputs
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Name of the OpenSearch domain"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.domain_name))
    error_message = "Domain name must be 3-28 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID for the OpenSearch domain"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for OpenSearch domain placement (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.vpc_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for multi-AZ deployment."
  }
}

# -----------------------------------------------------------------------------
# Optional Inputs
# -----------------------------------------------------------------------------

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.13"
}

variable "instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "or1.2xlarge.search"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = number
  default     = 3

  validation {
    condition     = var.instance_count >= 3
    error_message = "Instance count must be at least 3 for multi-AZ deployment."
  }
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB per node"
  type        = number
  default     = 500
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "ebs_iops" {
  description = "Provisioned IOPS for gp3 volumes"
  type        = number
  default     = 3000
}

variable "ebs_throughput" {
  description = "Provisioned throughput in MiB/s for gp3 volumes"
  type        = number
  default     = 125
}

variable "availability_zone_count" {
  description = "Number of availability zones for the domain"
  type        = number
  default     = 3

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "Availability zone count must be 2 or 3."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the OpenSearch domain"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access the OpenSearch domain"
  type        = list(string)
  default     = []
}
