# modules/network-policy/main.tf
#
# This module provides Kubernetes NetworkPolicy resources for securing your cluster
# NetworkPolicies are an important part of securing a GKE cluster
# They allow you to restrict pod-to-pod communication within the cluster
# Following the principle of least privilege

# Define local values for consistent naming
locals {
  default_deny_ingress_name = "default-deny-ingress"
  default_deny_egress_name  = "default-deny-egress"
  allow_dns_egress_name     = "allow-dns-egress"
  allow_api_egress_name     = "allow-api-egress"
  allow_intra_namespace_name = "allow-intra-namespace"
  allow_ingress_by_app_prefix = "allow-ingress-to-"
  allow_egress_to_external_prefix = "allow-egress-to-"
}

# Default deny all ingress traffic
# This policy selects all pods in the specified namespace and denies all ingress traffic to them.
# Other NetworkPolicies with higher precedence (lower order in the list or higher priority field, though priority is not standard)
# or more specific `podSelector` or `ingress` rules can override this.
resource "kubernetes_network_policy" "default_deny_ingress" {
  count = var.enable_default_policies ? 1 : 0 # Conditionally create based on variable

  metadata {
    name      = local.default_deny_ingress_name # Use local for name
    namespace = var.namespace
  }

  spec {
    pod_selector {} # Selects all pods in the namespace
    policy_types = ["Ingress"] # Apply only to ingress traffic
  }
}

# Default deny all egress traffic
# This policy selects all pods in the specified namespace and denies all egress traffic from them.
# Other NetworkPolicies with more specific `podSelector` or `egress` rules can override this.
resource "kubernetes_network_policy" "default_deny_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0 # Conditionally create based on variables

  metadata {
    name      = local.default_deny_egress_name # Use local for name
    namespace = var.namespace
  }

  spec {
    pod_selector {} # Selects all pods in the namespace
    policy_types = ["Egress"] # Apply only to egress traffic
  }
}

# Allow DNS resolution (required for most applications)
# This policy allows pods to make outbound connections to UDP and TCP port 53 (DNS).
# This is typically needed even with a default deny egress policy.
resource "kubernetes_network_policy" "allow_dns_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0 # Only needed if default egress is denied

  metadata {
    name      = local.allow_dns_egress_name # Use local for name
    namespace = var.namespace
  }

  spec {
    pod_selector {} # Apply to all pods in the namespace

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

    policy_types = ["Egress"] # Apply only to egress traffic
  }
}

# Allow traffic to Kubernetes API (required for service account token refresh and kubectl)
# This policy allows pods to make outbound connections to the GKE master IP on TCP port 443.
# This is crucial for pods using Workload Identity or needing to interact with the API server.
resource "kubernetes_network_policy" "allow_api_egress" {
  count = var.enable_default_policies && var.restrict_egress ? 1 : 0 # Only needed if default egress is denied

  metadata {
    name      = local.allow_api_egress_name # Use local for name
    namespace = var.namespace
  }

  spec {
    pod_selector {} # Apply to all pods in the namespace

    egress {
      ports {
        port     = 443
        protocol = "TCP"
      }

      to {
        ip_block {
          cidr = var.master_ipv4_cidr_block # Allow egress to the GKE master CIDR
        }
      }
    }

    policy_types = ["Egress"] # Apply only to egress traffic
  }
}

# Allow traffic between pods in the same namespace by label selector
# This policy allows pods with a specific label (defined by `var.app_label_selector`)
# to receive ingress traffic from other pods with the same label within the same namespace.
resource "kubernetes_network_policy" "allow_intra_namespace" {
  count = var.enable_intra_namespace_communication ? 1 : 0 # Conditionally create based on variable

  metadata {
    name      = local.allow_intra_namespace_name # Use local for name
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = var.app_label_selector # Select pods with this label
    }

    ingress {
      from {
        pod_selector {
          match_labels = var.app_label_selector # Allow ingress from pods with this label
        }
      }
    }

    policy_types = ["Ingress"] # Apply only to ingress traffic
  }
}

# Allow ingress to specific ports by application label
# This policy allows ingress traffic to pods with a specific 'app' label on defined ports,
# originating from pods with specified labels.
resource "kubernetes_network_policy" "allow_ingress_by_app" {
  for_each = var.enabled_apps_ingress # Create a policy for each entry in the map

  metadata {
    name      = "${local.allow_ingress_by_app_prefix}${each.key}" # Use local prefix and map key for name
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = {
        app = each.key # Select pods based on the map key (assuming 'app' label)
      }
    }

    ingress {
      ports {
        port     = each.value.port # Allow traffic on the specified port
        protocol = each.value.protocol # Allow traffic with the specified protocol
      }

      from {
        pod_selector {
          match_labels = each.value.from_pod_labels # Allow traffic from pods with these labels
        }
      }
    }

    policy_types = ["Ingress"] # Apply only to ingress traffic
  }
}

# Allow egress to specific external services (CIDRs)
# This policy allows pods with specific labels to make outbound connections
# to defined external CIDR blocks on specified ports and protocols.
resource "kubernetes_network_policy" "allow_egress_to_external" {
  for_each = var.allow_external_egress && var.restrict_egress ? var.external_egress_cidrs : {} # Conditionally create based on variables and map

  metadata {
    name      = "${local.allow_egress_to_external_prefix}${each.key}" # Use local prefix and map key for name
    namespace = var.namespace
  }

  spec {
    pod_selector {
      match_labels = each.value.pod_labels # Select pods based on these labels
    }

    egress {
      ports {
        port     = each.value.port # Allow traffic on the specified port
        protocol = each.value.protocol # Allow traffic with the specified protocol
      }

      to {
        ip_block {
          cidr = each.value.cidr # Allow egress to this CIDR block
        }
      }
    }

    policy_types = ["Egress"] # Apply only to egress traffic
  }
}
