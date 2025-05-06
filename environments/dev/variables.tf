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
  default     = "e2-micro"
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

# Additional configuration variables for enhanced modules

variable "deploy_network_policies" {
  description = "Whether to deploy Kubernetes Network Policies"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Whether to enable enhanced monitoring"
  type        = bool
  default     = true
}
