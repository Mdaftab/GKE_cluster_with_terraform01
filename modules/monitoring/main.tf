# modules/monitoring/main.tf
#
# This module sets up monitoring and logging for the GKE cluster
# It configures:
# - Cloud Monitoring dashboards
# - Log-based metrics
# - Alerting policies
# - Notification channels

# Define log-based metrics for security
resource "google_logging_metric" "security_metrics" {
  for_each = var.enable_security_metrics ? var.security_metrics : {}

  name        = each.key
  description = each.value.description
  filter      = each.value.filter
  project     = var.project_id

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# Create alert policies based on metrics
resource "google_monitoring_alert_policy" "alert_policies" {
  for_each = var.enable_alerts ? var.alerts : {}

  display_name = each.key
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = each.value.condition_display_name
    
    condition_threshold {
      filter     = each.value.filter
      duration   = each.value.duration
      comparison = each.value.comparison
      
      trigger {
        count = each.value.trigger_count
      }
      
      threshold_value = each.value.threshold_value
      
      aggregations {
        alignment_period   = each.value.alignment_period
        per_series_aligner = each.value.per_series_aligner
      }
    }
  }

  notification_channels = [
    for channel in var.notification_channels : google_monitoring_notification_channel.channels[channel].name
  ]

  user_labels = {
    environment = var.environment
    severity    = each.value.severity
  }
}

# Notification channels (email, SMS, Slack, etc.)
resource "google_monitoring_notification_channel" "channels" {
  for_each = var.enable_notifications ? var.notification_channels_config : {}

  display_name = each.key
  type         = each.value.type
  project      = var.project_id
  
  labels = each.value.labels
  
  sensitive_labels {
    auth_token = each.value.type == "slack" ? each.value.auth_token : null
    password   = each.value.type == "webhook_basicauth" ? each.value.password : null
  }
}

# Create custom dashboard for cluster monitoring
resource "google_monitoring_dashboard" "gke_dashboard" {
  count = var.create_dashboard ? 1 : 0
  
  dashboard_json = <<EOF
{
  "displayName": "GKE Cluster Dashboard for ${var.cluster_name}",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_MEAN"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Memory Usage",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/container/memory/used_bytes\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Disk Usage",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_node\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/node/disk/used_bytes\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_SUM"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Network Traffic",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"k8s_node\" AND resource.labels.cluster_name=\"${var.cluster_name}\" AND metric.type=\"kubernetes.io/node/network/received_bytes_count\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM"
                  }
                }
              }
            }
          ]
        }
      }
    ]
  }
}
EOF

  project = var.project_id
}

# Configure log exports to a storage bucket (for compliance and long-term storage)
resource "google_logging_project_sink" "log_sink" {
  count = var.enable_log_export ? 1 : 0
  
  name                   = "${var.project_name}-gke-logs"
  destination            = "storage.googleapis.com/${google_storage_bucket.log_bucket[0].name}"
  filter                 = "resource.type=\"k8s_cluster\" AND resource.labels.cluster_name=\"${var.cluster_name}\""
  project                = var.project_id
  unique_writer_identity = true
}

# Create storage bucket for logs
resource "google_storage_bucket" "log_bucket" {
  count = var.enable_log_export ? 1 : 0
  
  name          = "${var.project_id}-gke-logs"
  location      = var.log_storage_location
  project       = var.project_id
  force_destroy = var.log_bucket_force_destroy
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# Grant permission to write logs to the bucket
resource "google_storage_bucket_iam_binding" "log_writer" {
  count = var.enable_log_export ? 1 : 0
  
  bucket = google_storage_bucket.log_bucket[0].name
  role   = "roles/storage.objectCreator"
  
  members = [
    google_logging_project_sink.log_sink[0].writer_identity,
  ]
}