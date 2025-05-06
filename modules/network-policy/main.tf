# modules/network-policy/main.tf
#
# This module provides Kubernetes NetworkPolicy resources for securing your cluster
# NetworkPolicies are an important part of securing a GKE cluster
# They allow you to restrict pod-to-pod communication within the cluster
# Following the principle of least privilege

# Default deny all ingress traffic
resource "kubernetes_network_policy" "default_deny_ingress" {
  count = var.enable_default_policies ? 1 : 0

  metadata {
    name      = "default-deny-ingress"
    namespace = var.namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Default deny all egress traffic
resource "kubernetes_network_policy" "default_deny_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0

  metadata {
    name      = "default-deny-egress"
    namespace = var.namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]
  }
}

# Allow DNS resolution (required for most applications)
resource "kubernetes_network_policy" "allow_dns_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0

  metadata {
    name      = "allow-dns-egress"
    namespace = var.namespace
  }

  spec {
    pod_selector {}
    
    egress {
      ports {
        port     = 53
        protocol = "UDP"
      }
      ports {
        port     = 53
        protocol = "TCP"
      }
    }
    
    policy_types = ["Egress"]
  }
}

# Allow traffic to Kubernetes API (required for service account token refresh)
resource "kubernetes_network_policy" "allow_api_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0

  metadata {
    name      = "allow-api-egress"
    namespace = var.namespace
  }

  spec {
    pod_selector {}
    
    egress {
      ports {
        port     = 443
        protocol = "TCP"
      }
      
      to {
        ip_block {
          cidr = var.master_ipv4_cidr_block
        }
      }
    }
    
    policy_types = ["Egress"]
  }
}

# Allow traffic between pods in the same namespace by label selector
resource "kubernetes_network_policy" "allow_intra_namespace" {
  count = var.enable_intra_namespace_communication ? 1 : 0

  metadata {
    name      = "allow-intra-namespace"
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = var.app_label_selector
    }
    
    ingress {
      from {
        pod_selector {
          match_labels = var.app_label_selector
        }
      }
    }
    
    policy_types = ["Ingress"]
  }
}

# Allow ingress to specific ports by label
resource "kubernetes_network_policy" "allow_ingress_by_app" {
  for_each = var.enabled_apps_ingress

  metadata {
    name      = "allow-ingress-to-${each.key}"
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = each.key
      }
    }
    
    ingress {
      ports {
        port     = each.value.port
        protocol = each.value.protocol
      }
      
      from {
        pod_selector {
          match_labels = each.value.from_pod_labels
        }
      }
    }
    
    policy_types = ["Ingress"]
  }
}

# Allow egress to specific external services
resource "kubernetes_network_policy" "allow_egress_to_external" {
  for_each = var.allow_external_egress && var.restrict_egress ? var.external_egress_cidrs : {}

  metadata {
    name      = "allow-egress-to-${each.key}"
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = each.value.pod_labels
    }
    
    egress {
      ports {
        port     = each.value.port
        protocol = each.value.protocol
      }
      
      to {
        ip_block {
          cidr = each.value.cidr
        }
      }
    }
    
    policy_types = ["Egress"]
  }
}