# modules/gke/variables.tf

variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "zone" {
  description = "The zone to host the cluster in"
  type        = string
}

variable "network_name" {
  description = "The VPC network to host the cluster in"
  type        = string
}

variable "subnet_name" {
  description = "The subnetwork to host the cluster in"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  type        = string
}

variable "service_account" {
  description = "The service account to run nodes as"
  type        = string
}

variable "machine_type" {
  description = "The machine type to use for nodes"
  type        = string
  default     = "e2-medium"
}

variable "min_node_count" {
  description = "Minimum number of nodes in the NodePool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "Initial number of nodes in the NodePool"
  type        = number
  default     = 1
}

variable "environment" {
  description = "The environment this cluster will run in"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}
