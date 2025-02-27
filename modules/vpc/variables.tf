# modules/vpc/variables.tf

variable "project_id" {
  description = "The project ID to host the network in"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "region" {
  description = "The region to host the subnet in"
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "pod_cidr" {
  description = "The CIDR range for pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_cidr" {
  description = "The CIDR range for services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "master_ipv4_cidr_block" {
  description = "The CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "authorized_ip" {
  description = "The IP address authorized to access the GKE master"
  type        = string
}
