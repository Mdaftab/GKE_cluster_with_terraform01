# modules/gke/variables.tf
#
# Detailed variables for the GKE module with security-focused options

variable "project_id" {
  description = "The ID of the project in which the resources belong"
  type        = string
  validation {
    condition     = length(var.project_id) > 0 && can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be a valid GCP project ID."
  }
}

variable "project_name" {
  description = "The name of the project (used for resource naming)"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  validation {
    condition     = length(var.region) > 0
    error_message = "The region must not be empty."
  }
}

variable "zone" {
  description = "The zone to host the cluster in (required if is a zonal cluster)"
  type        = string
  validation {
    condition     = length(var.zone) > 0
    error_message = "The zone must not be empty."
  }
}

variable "network_name" {
  description = "The VPC network to host the cluster in"
  type        = string
}

variable "subnet_name" {
  description = "The subnetwork to host the cluster in"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  type        = string
}

variable "service_account" {
  description = "The service account to be used by the node VMs"
  type        = string
}

variable "machine_type" {
  description = "The machine type to use for node VMs"
  type        = string
}

variable "min_node_count" {
  description = "Minimum number of nodes in the NodePool"
  type        = number
  validation {
    condition     = var.min_node_count >= 0
    error_message = "The minimum node count must be a non-negative number."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
  validation {
    condition     = var.max_node_count >= var.min_node_count
    error_message = "The maximum node count must be greater than or equal to the minimum node count."
  }
}

variable "initial_node_count" {
  description = "Initial number of nodes in the NodePool"
  type        = number
  validation {
    condition     = var.initial_node_count >= var.min_node_count && var.initial_node_count <= var.max_node_count
    error_message = "The initial node count must be between the minimum and maximum node counts."
  }
}

variable "environment" {
  description = "The environment this cluster will run in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

# Enhanced security features

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for the cluster"
  type        = bool
  default     = false
}

variable "enable_database_encryption" {
  description = "Enable application-layer secrets encryption with Cloud KMS"
  type        = bool
  default     = false
}

variable "database_encryption_key" {
  description = "Cloud KMS key for database encryption"
  type        = string
  default     = ""
}

variable "enable_boot_disk_encryption" {
  description = "Enable node boot disk encryption"
  type        = bool
  default     = false
}

variable "boot_disk_kms_key" {
  description = "Cloud KMS key for boot disk encryption"
  type        = string
  default     = ""
}

variable "enable_dns_cache" {
  description = "Enable NodeLocal DNSCache"
  type        = bool
  default     = true
}

variable "enable_pod_security_policy" {
  description = "Enable pod security policy"
  type        = bool
  default     = false
}

variable "enable_master_authorized_networks" {
  description = "Enable master authorized networks"
  type        = bool
  default     = false
}

variable "master_authorized_cidr_blocks" {
  description = "List of CIDR blocks authorized to access the master"
  type        = list(object({
    cidr_block   = string
    display_name = string
  }))
  default     = []
}

variable "release_channel" {
  description = "The release channel for the GKE cluster (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "STABLE"
}

variable "node_taints" {
  description = "List of taints to apply to nodes"
  type        = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}
