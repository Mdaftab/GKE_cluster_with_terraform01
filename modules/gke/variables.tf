# modules/gke/variables.tf
#
# Detailed variables for the GKE module with security-focused options

variable "project_id" {
  description = "The ID of the project in which the resources belong"
  type        = string
}

variable "project_name" {
  description = "The name of the project (used for resource naming)"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "zone" {
  description = "The zone to host the cluster in (required if is a zonal cluster)"
  type        = string
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
}

variable "max_node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
}

variable "initial_node_count" {
  description = "Initial number of nodes in the NodePool"
  type        = number
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