# modules/vpc/variables.tf
#
# Input variables for the VPC module

variable "project_id" {
  description = "The project ID to host the network in"
  type        = string
  validation {
    condition     = length(var.project_id) > 0 && can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be a valid GCP project ID."
  }
}

variable "project_name" {
  description = "The name to use in resource names"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "The VPC name must not be empty."
  }
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
  validation {
    condition     = length(var.subnet_name) > 0
    error_message = "The subnet name must not be empty."
  }
}

variable "region" {
  description = "The region to host the subnet in"
  type        = string
  validation {
    condition     = length(var.region) > 0
    error_message = "The region must not be empty."
  }
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "The subnet_cidr must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "The CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "The pod_cidr must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "The CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "The service_cidr must be a valid CIDR block."
  }
}

variable "master_ipv4_cidr_block" {
  description = "The CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0))
    error_message = "The master_ipv4_cidr_block must be a valid CIDR block."
  }
}

variable "create_default_deny_rule" {
  description = "Whether to create a default deny-all firewall rule"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = true
}
