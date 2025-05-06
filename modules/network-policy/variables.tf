# modules/network-policy/variables.tf

variable "namespace" {
  description = "Kubernetes namespace to apply the network policies"
  type        = string
  default     = "default"
}

variable "enable_default_policies" {
  description = "Whether to enable default deny policies"
  type        = bool
  default     = true
}

variable "restrict_egress" {
  description = "Whether to restrict egress traffic"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "IP CIDR block of the GKE master"
  type        = string
}

variable "enable_intra_namespace_communication" {
  description = "Whether to allow pods within the same namespace to communicate"
  type        = bool
  default     = true
}

variable "app_label_selector" {
  description = "Label selector to use for intra-namespace communication"
  type        = map(string)
  default     = {
    app = "app"
  }
}

variable "enabled_apps_ingress" {
  description = "Map of applications to allow ingress to specific ports"
  type        = map(object({
    port           = number
    protocol       = string
    from_pod_labels = map(string)
  }))
  default     = {}
}

variable "allow_external_egress" {
  description = "Whether to allow egress to external services"
  type        = bool
  default     = false
}

variable "external_egress_cidrs" {
  description = "Map of external CIDRs to allow egress to"
  type        = map(object({
    cidr       = string
    port       = number
    protocol   = string
    pod_labels = map(string)
  }))
  default     = {}
}