# Environment / stage (dev, test, prod, etc.)
variable "env" {
  description = "Environment name suffix used for IAM naming (e.g., dev, qa, prod)"
  type        = string
}

# Optional permissions boundary policy name (without ARN)
# Set to null if you don't use boundaries.
variable "permissions_boundary_policy_name" {
  description = "Name of the IAM permissions boundary policy (without ARN). Set to null if not used."
  type        = string
  default     = null
}

# Common tags (if you are tagging resources)
variable "common_tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
