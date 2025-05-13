# environments/dev/outputs.tf

# environments/dev/outputs.tf

output "cluster_name" {
  description = "The name of the cluster"
  # The simplified GKE module outputs the cluster name directly
  value       = module.gke.cluster_name
}

output "cluster_region" {
  description = "The region of the cluster"
  value       = var.region # Get region from environment variable
}

output "project_id" {
  description = "The project ID where the cluster is created"
  value       = var.project_id # Get project ID from environment variable
}

output "endpoint" {
  description = "The IP address of the cluster master"
  sensitive   = true
  # The simplified GKE module outputs the endpoint directly
  value       = module.gke.endpoint
}

output "ca_certificate" {
  description = "The cluster ca certificate (base64 encoded)"
  sensitive   = true
  # The simplified GKE module outputs the CA certificate directly
  value       = module.gke.ca_certificate
}

output "get_credentials_command" {
  description = "Command to get credentials for the cluster"
  # Construct the command using environment variables and GKE module output
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# Removed outputs related to the security module
# output "service_account_email" {
#   description = "The email of the GKE service account"
#   value       = module.security.service_account_email
# }
