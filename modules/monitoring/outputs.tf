# modules/monitoring/outputs.tf

output "security_metrics" {
  description = "Map of security metrics created"
  value       = var.enable_security_metrics ? {
    for name, metric in google_logging_metric.security_metrics : name => {
      name        = metric.name
      description = metric.description
      filter      = metric.filter
    }
  } : {}
}

output "alert_policies" {
  description = "Map of alert policies created"
  value       = var.enable_alerts ? {
    for name, policy in google_monitoring_alert_policy.alert_policies : name => {
      name          = policy.display_name
      conditions    = policy.conditions
      documentation = policy.documentation
    }
  } : {}
}

output "notification_channels" {
  description = "Map of notification channels created"
  value       = var.enable_notifications ? {
    for name, channel in google_monitoring_notification_channel.channels : name => {
      name         = channel.display_name
      type         = channel.type
      verification = channel.verification_status
    }
  } : {}
}

output "dashboard_url" {
  description = "URL to the created dashboard"
  value       = var.create_dashboard ? "https://console.cloud.google.com/monitoring/dashboards/custom/${element(split("/", google_monitoring_dashboard.gke_dashboard[0].id), length(split("/", google_monitoring_dashboard.gke_dashboard[0].id)) - 1)}" : null
}

output "log_sink" {
  description = "Log sink information"
  value       = var.enable_log_export ? {
    name                   = google_logging_project_sink.log_sink[0].name
    destination            = google_logging_project_sink.log_sink[0].destination
    filter                 = google_logging_project_sink.log_sink[0].filter
    writer_identity        = google_logging_project_sink.log_sink[0].writer_identity
  } : null
}

output "log_bucket" {
  description = "Log storage bucket"
  value       = var.enable_log_export ? {
    name     = google_storage_bucket.log_bucket[0].name
    location = google_storage_bucket.log_bucket[0].location
    url      = google_storage_bucket.log_bucket[0].url
  } : null
}