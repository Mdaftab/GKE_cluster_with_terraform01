# modules/security/variables.tf

variable "project_id" {
  description = "The ID of the project where resources will be created"
  type        = string
  validation {
    condition     = length(var.project_id) > 0 && can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id must be a valid GCP project ID."
  }
}

variable "project_name" {
  description = "The name of the project (used for naming resources)"
  type        = string
}

variable "service_account_id" {
  description = "ID for the GKE service account"
  type        = string
  default     = "gke-node-sa"
  validation {
    condition     = length(var.service_account_id) > 0
    error_message = "The service_account_id must not be empty."
  }
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name must not be empty."
  }
}

variable "enable_cloud_armor" {
  description = "Whether to enable Cloud Armor security policies"
  type        = bool
  default     = false
}

variable "enable_binary_authorization" {
  description = "Whether to enable Binary Authorization"
  type        = bool
  default     = false
}

variable "attestor_public_key" {
  description = "Public key for Binary Authorization attestor"
  type        = string
  default     = ""
}

variable "enable_secret_manager" {
  description = "Whether to create secrets in Secret Manager"
  type        = bool
  default     = false
}

variable "secrets" {
  description = "Map of secrets to store in Secret Manager"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "apply_org_policies" {
  description = "Whether to apply organization policies"
  type        = bool
  default     = false
}
