# modules/vpc/main.tf
#
# This module creates a secure VPC network for GKE with:
# - Custom VPC with no auto-subnets
# - Dedicated subnet per environment
# - Separate IP ranges for primary, pod, and service networks
# - Private Google access for private clusters
# - Cloud NAT for internet egress from private nodes
# - Restricted firewall rules following least privilege
# - VPC flow logs for network monitoring and security

# Use Google's VPC module as a base
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.0"

  project_id   = var.project_id
  network_name = var.vpc_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
      description           = "GKE subnet with private Google access enabled"
    }
  ]

  secondary_ranges = {
    "${var.subnet_name}" = [
      {
        range_name    = "${var.subnet_name}-pods"
        ip_cidr_range = var.pod_cidr
      },
      {
        range_name    = "${var.subnet_name}-services"
        ip_cidr_range = var.service_cidr
      }
    ]
  }

  # Configure flow logs for the subnet if enabled
  dynamic "subnets_flow_logs" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      subnet_name          = var.subnet_name
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Firewall rules for GKE internal communication
# Allow internal traffic between GKE nodes, pods, and master
resource "google_compute_firewall" "gke_internal" {
  name        = "${var.vpc_name}-gke-internal"
  network     = module.vpc.network_name
  description = "Allow internal traffic between GKE nodes, pods, and master"
  priority    = 1000 # Default priority

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  # Source ranges include the subnet, pod, service, and master CIDRs
  source_ranges = [
    var.subnet_cidr,
    var.pod_cidr,
    var.service_cidr,
    var.master_ipv4_cidr_block
  ]

  log_config {
    metadata = "INCLUDE_ALL_METADATA" # Log all metadata for analysis
  }
}

# Allow master to access node pools and vice versa
resource "google_compute_firewall" "master_to_nodes" {
  name        = "${var.vpc_name}-master-to-nodes"
  network     = module.vpc.network_name
  description = "Allow the GKE master to reach the nodes on required ports"
  direction   = "INGRESS"
  priority    = 1000 # Default priority

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "8443", "9443"] # Required ports for kubelet, webhooks, etc.
  }

  source_ranges = [var.master_ipv4_cidr_block] # Source is the GKE master CIDR
  target_tags   = ["gke-${var.project_name}"] # Target nodes with GKE tag

  log_config {
    metadata = "INCLUDE_ALL_METADATA" # Log all metadata for analysis
  }
}

# Default deny all ingress (higher priority = lower number, so this rule has lower priority than allows)
resource "google_compute_firewall" "deny_all_ingress" {
  count       = var.create_default_deny_rule ? 1 : 0 # Conditionally create based on variable
  name        = "${var.vpc_name}-deny-all-ingress"
  network     = module.vpc.network_name
  description = "Default deny for all ingress traffic"
  direction   = "INGRESS"
  priority    = 65534 # Low priority to ensure allow rules take precedence

  deny {
    protocol = "all" # Deny all protocols
  }

  source_ranges = ["0.0.0.0/0"] # Apply to all sources

  log_config {
    metadata = "INCLUDE_ALL_METADATA" # Log denied traffic for security analysis
  }
}

# NAT configuration for private GKE nodes to access the internet
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = module.vpc.network_name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY" # Automatically allocate NAT IPs
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # Apply NAT to all IP ranges in the subnet

  log_config {
    enable = true
    filter = "ERRORS_ONLY" # Log NAT errors
  }

  # Timeout configurations (default values are often sufficient, but can be tuned)
  tcp_established_idle_timeout_sec = 1200
  tcp_transitory_idle_timeout_sec  = 30

  # Set minimum NAT ports per VM to reduce potential for source port exhaustion
  min_ports_per_vm = 64 # Recommended minimum
}
