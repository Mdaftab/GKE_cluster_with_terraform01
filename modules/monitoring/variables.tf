# modules/monitoring/variables.tf

variable "project_id" {
  description = "The ID of the project where monitoring resources will be created"
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

variable "cluster_name" {
  description = "Name of the GKE cluster to monitor"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "enable_security_metrics" {
  description = "Whether to enable security-related log metrics"
  type        = bool
  default     = true
}

variable "security_metrics" {
  description = "Map of security metrics to create"
  type        = map(object({
    description = string
    filter      = string
  }))
  default     = {
    "cluster_authorization_failures" = {
      description = "Count of authorization failures in the GKE cluster"
      filter      = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"CLUSTER_NAME\" AND log_name=\"projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity\" AND protoPayload.status.code=7"
    },
    "pod_security_violations" = {
      description = "Count of pod security policy violations"
      filter      = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"CLUSTER_NAME\" AND textPayload:\"Error validating pod\""
    }
  }
}

variable "enable_alerts" {
  description = "Whether to enable alert policies"
  type        = bool
  default     = true
}

variable "alerts" {
  description = "Map of alerts to create"
  type        = map(object({
    condition_display_name = string
    filter                = string
    duration              = string
    comparison            = string
    threshold_value       = number
    alignment_period      = string
    per_series_aligner    = string
    trigger_count         = number
    severity              = string
  }))
  default     = {
    "high_cpu_usage" = {
      condition_display_name = "GKE Cluster CPU usage above threshold"
      filter                = "resource.type=\"k8s_node\" AND resource.labels.cluster_name=\"CLUSTER_NAME\" AND metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\"",
      duration              = "300s"
      comparison            = "COMPARISON_GT"
      threshold_value       = 0.8
      alignment_period      = "300s"
      per_series_aligner    = "ALIGN_MEAN"
      trigger_count         = 1
      severity              = "warning"
    },
    "high_memory_usage" = {
      condition_display_name = "GKE Cluster memory usage above threshold"
      filter                = "resource.type=\"k8s_node\" AND resource.labels.cluster_name=\"CLUSTER_NAME\" AND metric.type=\"kubernetes.io/node/memory/allocatable_utilization\"",
      duration              = "300s"
      comparison            = "COMPARISON_GT"
      threshold_value       = 0.8
      alignment_period      = "300s"
      per_series_aligner    = "ALIGN_MEAN"
      trigger_count         = 1
      severity              = "warning"
    }
  }
}

variable "notification_channels" {
  description = "List of notification channel names to use for alerts"
  type        = list(string)
  default     = ["email", "slack"]
}

variable "enable_notifications" {
  description = "Whether to enable notification channels"
  type        = bool
  default     = true
}

variable "notification_channel_configs" {
  description = "Configuration for notification channels (sensitive data)"
  type        = map(object({
    type       = string
    labels     = map(string)
    auth_token = string
    password   = string
  }))
  default     = {
    "email" = {
      type       = "email"
      labels     = {
        email_address = "admin@example.com"
      }
      auth_token = ""
      password   = ""
    },
    "slack" = {
      type       = "slack"
      labels     = {
        channel_name = "#alerts"
      }
      auth_token = "xoxb-your-token"
      password   = ""
    }
  }
  sensitive   = true
}

variable "create_dashboard" {
  description = "Whether to create a custom dashboard"
  type        = bool
  default     = true
}

variable "enable_log_export" {
  description = "Whether to export logs to a storage bucket"
  type        = bool
  default     = false
}

variable "log_storage_location" {
  description = "Location for the log storage bucket"
  type        = string
  default     = "US"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days > 0
    error_message = "Log retention days must be a positive number."
  }
}

variable "log_bucket_force_destroy" {
  description = "Whether to force destroy the log bucket even if it contains objects"
  type        = bool
  default     = false
}
