# modules/security/outputs.tf

output "service_account_email" {
  description = "Email of the service account created for GKE nodes"
  value       = google_service_account.gke_sa.email
}

output "service_account_id" {
  description = "ID of the service account created for GKE nodes"
  value       = google_service_account.gke_sa.id
}

output "security_policy_id" {
  description = "ID of the Cloud Armor security policy"
  value       = var.enable_cloud_armor ? google_compute_security_policy.security_policy[0].id : null
}

output "security_policy_name" {
  description = "Name of the Cloud Armor security policy"
  value       = var.enable_cloud_armor ? google_compute_security_policy.security_policy[0].name : null
}

output "binary_authorization_policy_id" {
  description = "ID of the Binary Authorization policy"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.policy[0].id : null
}