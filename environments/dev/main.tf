terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# Configure providers
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Configure Kubernetes provider using GKE credentials
data "google_client_config" "default" {}

# Create VPC using our enhanced network module
module "vpc" {
  source = "../../modules/vpc"

  project_id             = var.project_id
  project_name           = var.project_name
  vpc_name               = "${var.project_name}-vpc"
  subnet_name            = "${var.project_name}-subnet"
  region                 = var.region
  subnet_cidr            = var.subnet_cidr
  pod_cidr               = var.pod_cidr
  service_cidr           = var.service_cidr
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  create_default_deny_rule = true
  enable_flow_logs       = true
}

# Create Security module for IAM and security configurations
module "security" {
  source = "../../modules/security"
  
  project_id            = var.project_id
  project_name          = var.project_name
  service_account_id    = "${var.project_name}-gke-sa"
  cluster_name          = "${var.project_name}-cluster"
  enable_cloud_armor    = false
  enable_binary_authorization = false
  enable_secret_manager = false
  apply_org_policies    = false
}

# Create GKE cluster using our security-enhanced module
module "gke" {
  source = "../../modules/gke"

  project_id             = var.project_id
  project_name           = var.project_name
  cluster_name           = "${var.project_name}-cluster"
  region                 = var.region
  zone                   = var.zone
  network_name           = module.vpc.network_name
  subnet_name            = module.vpc.subnet_name
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  service_account        = module.security.service_account_email
  machine_type           = var.machine_type
  min_node_count         = var.min_node_count
  max_node_count         = var.max_node_count
  initial_node_count     = var.initial_node_count
  environment            = var.environment
  
  # Security configurations
  enable_binary_authorization = false
  enable_database_encryption  = false
  enable_boot_disk_encryption = false
  enable_dns_cache            = true
  enable_pod_security_policy  = false
  enable_master_authorized_networks = false
  release_channel             = "STABLE"
  
  # Apply default node taints if needed
  node_taints                 = []

  # depends_on = [module.vpc, module.security] # Remove dependency on security module
}

# Optional: Deploy Network Policies if cluster has workloads
module "network_policy" {
  source = "../../modules/network-policy"
  count  = var.deploy_network_policies ? 1 : 0

  namespace              = "default"
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  enable_default_policies = true
  restrict_egress         = false

  # Examples of app-specific network policies
  enabled_apps_ingress = {
    "demo-app" = {
      port = 8080
      protocol = "TCP"
      from_pod_labels = {
        "app" = "demo-app"
      }
    }
  }

  depends_on = [module.gke]
}

# Removed Monitoring module as per simplification request
# module "monitoring" {
#   source = "../../modules/monitoring"
#   count  = var.enable_monitoring ? 1 : 0
#
#   project_id   = var.project_id
#   project_name = var.project_name
#   cluster_name = module.gke.cluster_name
#   environment  = var.environment
#
#   enable_security_metrics   = true
#   enable_alerts             = true
#   enable_notifications      = false
#   create_dashboard          = true
#   enable_log_export         = false
#
#   depends_on = [module.gke]
# }

# Removed Security module as per simplification request
# module "security" {
#   source = "../../modules/security"
#
#   project_id            = var.project_id
#   project_name          = var.project_name
#   service_account_id    = "${var.project_name}-gke-sa"
#   cluster_name          = "${var.project_name}-cluster"
#   enable_cloud_armor    = false
#   enable_binary_authorization = false
#   enable_secret_manager = false
#   apply_org_policies    = false
# }
