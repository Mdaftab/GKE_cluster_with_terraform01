# modules/gke/self_destruct.tf

# Only create these resources if auto_destroy_hours is set greater than 0
locals {
  create_self_destruct = var.auto_destroy_hours > 0
  destroy_time         = timeadd(timestamp(), "${var.auto_destroy_hours}h")
  notification_time    = timeadd(local.destroy_time, "-1h") # Notify 1 hour before destruction
}

# Cloud Scheduler job to trigger self-destruction
resource "google_cloud_scheduler_job" "self_destruct" {
  count            = local.create_self_destruct ? 1 : 0
  name             = "self-destruct-${var.cluster_name}"
  description      = "Triggers the destruction of ${var.cluster_name} cluster after ${var.auto_destroy_hours} hours"
  schedule         = "0 * * * *" # Run hourly to check destruction time
  time_zone        = "UTC"
  project          = var.project_id
  region           = var.region
  attempt_deadline = "320s"

  http_target {
    uri         = "https://cloudresourcemanager.googleapis.com/v1/projects/${var.project_id}:testIamPermissions"
    http_method = "POST"
    body = base64encode(jsonencode({
      function      = "self_destruct",
      cluster_name  = var.cluster_name,
      region        = var.region,
      project_id    = var.project_id,
      destroy_time  = local.destroy_time,
      current_time  = timestamp()
    }))

    oauth_token {
      service_account_email = var.service_account
    }
  }
}

# Cloud Pub/Sub topic for self-destruct notifications
resource "google_pubsub_topic" "self_destruct_notification" {
  count   = local.create_self_destruct && var.auto_destroy_notification_email != "" ? 1 : 0
  name    = "self-destruct-${var.cluster_name}-notification"
  project = var.project_id
}

# Cloud Scheduler job to send notification before destruction
resource "google_cloud_scheduler_job" "self_destruct_notification" {
  count            = local.create_self_destruct && var.auto_destroy_notification_email != "" ? 1 : 0
  name             = "self-destruct-notification-${var.cluster_name}"
  description      = "Sends notification before the destruction of ${var.cluster_name} cluster"
  schedule         = "0 * * * *" # Run hourly to check notification time
  time_zone        = "UTC"
  project          = var.project_id
  region           = var.region
  attempt_deadline = "320s"

  pubsub_target {
    topic_name = google_pubsub_topic.self_destruct_notification[0].id
    data = base64encode(jsonencode({
      function         = "self_destruct_notification",
      cluster_name     = var.cluster_name,
      region           = var.region,
      project_id       = var.project_id,
      notification_time = local.notification_time,
      destroy_time     = local.destroy_time,
      current_time     = timestamp(),
      email            = var.auto_destroy_notification_email
    }))
  }
}

# Add this to cluster labels to indicate self-destruction time
locals {
  self_destruct_labels = local.create_self_destruct ? {
    "self-destruct-time" = replace(local.destroy_time, ":", "-")
  } : {}
}