# modules/vpc/main.tf

# Network Architecture:
# - Custom VPC with no auto-subnets
# - Dedicated subnet per environment
# - Separate IP ranges for:
#   * Primary subnet (specified in subnet_cidr)
#   * Pod network (specified in pod_cidr)
#   * Service network (specified in svc_cidr)

# Use Google's VPC module as a base
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 7.0"

  project_id   = var.project_id
  network_name = var.vpc_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = var.subnet_name
      subnet_ip     = var.subnet_cidr
      subnet_region = var.region
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
}

# Firewall rules for GKE internal communication
resource "google_compute_firewall" "gke_internal" {
  name    = "${var.vpc_name}-gke-internal"
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_cidr,
    var.pod_cidr,
    var.service_cidr,
    var.master_ipv4_cidr_block
  ]
}

# NAT configuration for private GKE nodes
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = module.vpc.network_name
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
