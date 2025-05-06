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
  enable_private_endpoint = false  # False allows accessing from authorized networks
  enable_private_nodes    = true   # Nodes have only private IPs
  deletion_protection     = false  # Set to true for production
  
  # Disable the legacy Compute Engine API access (more secure)
  enable_legacy_abac      = false
  
  # Enable secrets encryption with Google KMS
  database_encryption = [{
    state    = "ENCRYPTED"
    key_name = var.enable_database_encryption ? var.database_encryption_key : ""
  }]
  
  # Enable binary authorization (container image security)
  enable_binary_authorization = var.enable_binary_authorization
  
  # Enable NodeLocal DNSCache for better DNS performance and security
  dns_cache = var.enable_dns_cache
  
  # Enable Workload Identity for secure pod identity
  workload_identity_config = [{
    workload_pool = "${var.project_id}.svc.id.goog"
  }]
  
  # Enable Dataplane V2 (optimized networking)
  datapath_provider = "ADVANCED_DATAPATH"
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Release channel for GKE version management
  release_channel = var.release_channel

  node_pools = [
    {
      name               = "small-pool"
      machine_type       = var.machine_type
      min_count          = var.min_node_count
      max_count          = var.max_node_count
      local_ssd_count    = 0
      disk_size_gb       = 20  # Slightly larger for security updates
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      spot               = true
      initial_node_count = var.initial_node_count
      
      # Enable secure boot for node security
      secure_boot        = true
      
      # Enable integrity monitoring
      integrity_monitoring = true
      
      # Boot disk KMS encryption (optional)
      boot_disk_kms_key  = var.enable_boot_disk_encryption ? var.boot_disk_kms_key : null
      
      # Tags for network filtering
      tags               = ["gke-${var.cluster_name}", "private-cluster-node"]
      
      # Metadata for startup scripts (if needed)
      metadata = {
        "disable-legacy-endpoints" = "true"
      }
      
      # Use Google managed service account or custom service account
      service_account   = var.service_account == "" ? "default" : var.service_account
      
      # Workload Identity enabled by setting GKE_METADATA
      workload_metadata_config = {
        mode = "GKE_METADATA"
      }
    }
  ]

  # Apply least privilege principle with minimal scopes
  node_pools_oauth_scopes = {
    small-pool = [
      "https://www.googleapis.com/auth/devstorage.read_only",   # Read-only access to Storage
      "https://www.googleapis.com/auth/logging.write",          # Write logs
      "https://www.googleapis.com/auth/monitoring",             # Monitoring
      "https://www.googleapis.com/auth/servicecontrol",         # Service control
      "https://www.googleapis.com/auth/service.management.readonly", # Service management (read)
      "https://www.googleapis.com/auth/trace.append"            # Trace appending
    ]
  }

  # Labels for better resource tracking and management
  node_pools_labels = {
    small-pool = {
      environment = var.environment
      managed-by  = "terraform"
      node-pool   = "small-pool"
    }
  }

  # Metadata for each pool (default to secure configuration)
  node_pools_metadata = {
    small-pool = {
      disable-legacy-endpoints = "true"
      block-project-ssh-keys   = "true"  # Block project-wide SSH keys
    }
  }

  # Optional taints (for dedicated workloads)
  node_pools_taints = {
    small-pool = var.node_taints
  }

  # Network tags for firewall rules
  node_pools_tags = {
    small-pool = [
      "gke-${var.cluster_name}",
      "private-cluster-node",
      "${var.environment}-node"
    ]
  }

  # Enhanced security features
  enable_shielded_nodes                = true
  monitoring_enable_managed_prometheus = true
  logging_enabled_components           = ["SYSTEM_COMPONENTS", "WORKLOADS"]

  # Set to higher logging and monitoring levels for security
  # Comment or adjust for cost optimization
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes" 
  
  # Pod security policy (optional)
  pod_security_policy_config = var.enable_pod_security_policy ? [{
    enabled = true
  }] : []
  
  # Network security
  # Configure master authorized networks (optional)
  master_authorized_networks_config = var.enable_master_authorized_networks ? [{
    cidr_blocks = var.master_authorized_cidr_blocks
  }] : []

  # RBAC configuration
  grant_registry_access = true
  
  # Configure maintenance window to minimize impact
  maintenance_policy = [{
    recurring_window = {
      start_time = "2022-01-01T09:00:00Z" # Weekend maintenance only
      end_time   = "2022-01-01T17:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }]

  # Intranode visibility for network policy enforcement
  enable_intranode_visibility = true
  
  # IP masquerade agent for enhanced network security
  ip_masq_agent_config = [{
    enabled = true
  }]

  # Add labels for better tracking
  cluster_resource_labels = {
    environment  = var.environment
    managed_by   = "terraform"
    created_at   = formatdate("YYYY-MM-DD", timestamp())
    purpose      = "development"
    created_by   = "terraform"
    project      = var.project_name
    cluster_name = var.cluster_name
    vpc_network  = var.network_name
  }

  # Network Policy
  network_policy          = true
  network_policy_provider = "CALICO"

  # Enable Workload Identity
  node_metadata = "GKE_METADATA"
  
  # Additional security hardening
  security_posture_config = [{
    mode = "BASIC"
    vulnerability_mode = "VULNERABILITY_ENTERPRISE"
  }]
}
