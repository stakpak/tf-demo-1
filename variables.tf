variable "vpc_id" {
  description = "VPC ID where the Tailscale instance will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (vpc-xxxxxxxx)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Tailscale instance"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the Tailscale instance"
  type        = string
  default     = "t3.micro"

  validation {
    condition = can(regex("^[a-z][0-9][a-z]?\\.[a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type format."
  }
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional)"
  type        = string
  default     = null
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key for auto-registration"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.tailscale_auth_key) > 0
    error_message = "Tailscale authentication key cannot be empty."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}