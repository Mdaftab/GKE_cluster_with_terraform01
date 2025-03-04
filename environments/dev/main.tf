terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure providers
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

# Create VPC using our module
module "vpc" {
  source = "../../modules/vpc"

  project_id             = var.project_id
  vpc_name               = "${var.project_name}-vpc"
  subnet_name            = "${var.project_name}-subnet"
  region                 = var.region
  subnet_cidr            = var.subnet_cidr
  pod_cidr               = var.pod_cidr
  service_cidr           = var.service_cidr
  master_ipv4_cidr_block = var.master_ipv4_cidr_block
  authorized_ip          = var.authorized_ip
}

# Create GKE cluster using our module
module "gke" {
  source = "../../modules/gke"

  project_id             = var.project_id
  cluster_name           = "${var.project_name}-cluster"
  region                 = var.region
  zone                   = var.zone
  network_name           = module.vpc.network_name
  subnet_name            = module.vpc.subnet_name
  machine_type           = var.machine_type
  authorized_ip          = var.authorized_ip
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  depends_on = [module.vpc]
}
