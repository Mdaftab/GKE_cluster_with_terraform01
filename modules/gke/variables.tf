# modules/gke/variables.tf

variable "project_id" {
  description = "The ID of the project in which the resources belong"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "zone" {
  description = "The zone to host the cluster in (required if is a zonal cluster)"
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
  description = "The service account to be used by the node VMs"
  type        = string
}

variable "machine_type" {
  description = "The machine type to use for node VMs"
  type        = string
}

variable "min_node_count" {
  description = "Minimum number of nodes in the NodePool"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of nodes in the NodePool"
  type        = number
}

variable "initial_node_count" {
  description = "Initial number of nodes in the NodePool"
  type        = number
}

variable "environment" {
  description = "The environment this cluster will run in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "auto_destroy_hours" {
  description = "If set, the cluster will be automatically destroyed after this many hours. Set to 0 to disable auto-destruction."
  type        = number
  default     = 0
}

variable "auto_destroy_notification_email" {
  description = "Email to notify before auto-destruction of cluster"
  type        = string
  default     = ""
}