# modules/gke/main.tf

# Use Google's GKE module as a base
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 29.0"

  project_id              = var.project_id
  name                    = var.cluster_name
  region                  = var.region
  zones                   = [var.zone]
  network                 = var.network_name
  subnetwork              = var.subnet_name
  ip_range_pods           = "${var.subnet_name}-pods"
  ip_range_services       = "${var.subnet_name}-services"
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_private_endpoint = false
  enable_private_nodes    = true
  deletion_protection     = false
  master_authorized_networks = [{
    cidr_block   = "${var.authorized_ip}/32"
    display_name = "VPN"
  }]

  remove_default_node_pool = true
  initial_node_count       = 1

  node_pools = [
    {
      name               = "small-pool"
      machine_type       = "e2-micro"
      min_count          = 1
      max_count          = 2
      local_ssd_count    = 0
      disk_size_gb       = 10
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      spot               = true
      initial_node_count = 1
    }
  ]

  node_pools_oauth_scopes = {
    small-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }

  node_pools_labels = {
    small-pool = {}
  }

  node_pools_metadata = {
    small-pool = {}
  }

  node_pools_taints = {
    small-pool = []
  }

  node_pools_tags = {
    small-pool = []
  }

  # Security
  enable_shielded_nodes                = true
  monitoring_enable_managed_prometheus = true
  logging_enabled_components           = ["SYSTEM_COMPONENTS"]

  # Minimal monitoring for cost savings
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  # RBAC
  grant_registry_access = true

  # Add labels for better tracking
  cluster_resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
    updated_by  = "github-actions"
    team        = "devops"
  }

  # Network Policy
  network_policy          = true
  network_policy_provider = "CALICO"

  # Enable Workload Identity
  workload_identity_config = {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
