# environments/dev/variables.tf

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The GCP project name"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
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

variable "auto_destroy_hours" {
  description = "Number of hours after which the cluster will be automatically destroyed. Set to 0 to disable auto-destroy."
  type        = number
  default     = 0
}

variable "auto_destroy_notification_email" {
  description = "Email to notify before auto-destruction of cluster"
  type        = string
  default     = ""
}
