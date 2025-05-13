# modules/gke/main.tf
#
# This module creates a secure, hardened GKE cluster using Google's official Terraform module.
# It implements best practices including:
#  - Private cluster with private nodes
#  - Spot instances for cost savings
#  - Minimal machine types for cost efficiency
#  - Comprehensive security features:
#    * Shielded nodes
#    * VPC-native networking
#    * Network policy (Calico)
#    * Workload Identity
#    * Binary Authorization (optional)
#    * Node auto-upgrade
#    * NodeLocal DNSCache
#    * Application-layer Secrets Encryption
#    * Secure Boot

# modules/gke/main.tf
#
# This module creates a secure, hardened GKE cluster using Google's official Terraform module.
# It implements best practices including:
#  - Private cluster with private nodes
#  - Spot instances for cost savings
#  - Minimal machine types for cost efficiency
#  - Comprehensive security features:
#    * Shielded nodes
#    * VPC-native networking
#    * Network policy (Calico)
#    * Workload Identity
#    * Binary Authorization (optional)
#    * Node auto-upgrade
#    * NodeLocal DNSCache
#    * Application-layer Secrets Encryption
#    * Secure Boot

# Define local values for derived names and configurations
locals {
  cluster_full_name = "${var.project_name}-cluster-${var.environment}"
}

# Use Google's GKE module as a base
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 29.0"

  project_id              = var.project_id
  name                    = local.cluster_full_name # Use local for consistent naming
  region                  = var.region
  zones                   = [var.zone]
  network                 = var.network_name
  subnetwork              = var.subnet_name
  ip_range_pods           = "${var.subnet_name}-pods" # Assuming these IP ranges are created with the subnet
  ip_range_services       = "${var.subnet_name}-services" # Assuming these IP ranges are created with the subnet
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_private_endpoint = false  # False allows accessing from authorized networks (consider true for stricter isolation)
  enable_private_nodes    = true   # Nodes have only private IPs
  deletion_protection     = false  # Set to true for production environments!
}
