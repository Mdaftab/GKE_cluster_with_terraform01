# modules/security/main.tf
#
# This module implements security best practices for GKE deployments:
# - Least privilege service account for GKE nodes
# - Binary Authorization (optional)
# - Security policies (Cloud Armor) (optional)
# - Secret Management (optional)
# - Organization Policies (optional)

# Define local values for consistent naming
locals {
  gke_sa_name      = var.service_account_id
  attestor_name    = "${var.project_name}-attestor"
  attestor_note_name = "${var.project_name}-attestor-note"
  security_policy_name = "${var.project_name}-security-policy"
}

# Create dedicated service account for GKE nodes
resource "google_service_account" "gke_sa" {
  account_id   = local.gke_sa_name # Use local for SA name
  display_name = "GKE Service Account for ${var.cluster_name}"
  description  = "Service account for GKE nodes with minimal permissions"
  project      = var.project_id
}

# Grant minimum necessary permissions to the service account
# These roles are commonly needed for GKE nodes to interact with GCP services
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",               # Write logs to Cloud Logging
    "roles/monitoring.metricWriter",         # Write metrics to Cloud Monitoring
    "roles/monitoring.viewer",               # Read metrics from Cloud Monitoring
    "roles/stackdriver.resourceMetadata.writer", # Write resource metadata to Stackdriver
    "roles/artifactregistry.reader",         # Pull images from Artifact Registry
    # Add other roles as needed based on workload requirements (e.g., Storage Object Viewer)
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Security Policy (Cloud Armor) - Optional, based on variable
# Example policy rules are included; customize based on your needs
resource "google_compute_security_policy" "security_policy" {
  count = var.enable_cloud_armor ? 1 : 0 # Conditionally create based on variable

  name        = local.security_policy_name # Use local for policy name
  description = "Security policy for ${var.cluster_name}"
  project     = var.project_id

  # Block access from countries with high rates of attacks (example rule)
  rule {
    action   = "deny(403)" # Deny with 403 Forbidden response
    priority = "1000"      # Lower number = higher priority
    match {
      expr {
        expression = "origin.region_code == 'RU' || origin.region_code == 'CN' || origin.region_code == 'IR' || origin.region_code == 'KP'"
      }
    }
    description = "Block access from high-risk countries"
  }

  # Rate limiting rule (example rule)
  rule {
    action   = "rate_based_ban" # Ban clients exceeding the rate limit
    priority = "1001"
    match {
      expr {
        expression = "true" # Apply to all requests
      }
    }
    rate_limit_options {
      conform_action = "allow" # Allow requests below the threshold
      exceed_action  = "deny(429)" # Deny with 429 Too Many Requests response
      rate_limit_threshold {
        count        = 100 # 100 requests
        interval_sec = 60  # per 60 seconds
      }
    }
    description = "Rate limiting"
  }

  # Default rule (required) - Allows all traffic by default if no higher priority rule matches
  rule {
    action   = "allow"
    priority = "2147483647" # Highest possible priority (lowest precedence)
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"] # Apply to all source IP ranges
      }
    }
    description = "Default rule, higher priority rules override it"
  }
}

# Binary Authorization Policy (Optional, based on variable)
# Enforces that only trusted container images can be deployed
resource "google_binary_authorization_policy" "policy" {
  count = var.enable_binary_authorization ? 1 : 0 # Conditionally create based on variable

  project = var.project_id

  # Define a whitelist of image repositories that are always allowed
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*" # Allow images from project's Container Registry
  }

  admission_whitelist_patterns {
    name_pattern = "us-docker.pkg.dev/${var.project_id}/*" # Allow images from project's Artifact Registry
  }

  # Default rule: require attestations for all images not in the whitelist
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION" # Require images to be attested
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG" # Block deployment and log violations

    # Specify which attestors must have attested the image
    require_attestations_by = [
      google_binary_authorization_attestor.attestor[0].name, # Requires attestation by the created attestor
    ]
  }

  # Enable evaluation of the global policy (policies set at the organization/folder level)
  global_policy_evaluation_mode = "ENABLE"
}

# Binary Authorization Attestor (Created only if binary authorization is enabled)
# Represents a trusted party that verifies container images
resource "google_binary_authorization_attestor" "attestor" {
  count = var.enable_binary_authorization ? 1 : 0 # Conditionally create based on variable

  name = local.attestor_name # Use local for attestor name
  project = var.project_id

  # Link the attestor to a Container Analysis Note
  attestation_authority_note {
    note_reference = google_container_analysis_note.note[0].name # Reference the created note
    public_keys {
      id = "1" # Key ID
      pkix_public_key {
        public_key_pem      = var.attestor_public_key # Use variable for public key
        signature_algorithm = "RSA_PSS_2048_SHA256" # Specify signature algorithm
      }
    }
  }
}

# Binary Authorization Note (Created only if binary authorization is enabled)
# A Container Analysis Note associated with the attestor
resource "google_container_analysis_note" "note" {
  count = var.enable_binary_authorization ? 1 : 0 # Conditionally create based on variable

  name    = local.attestor_note_name # Use local for note name
  project = var.project_id

  attestation_authority {
    hint {
      human_readable_name = "Attestor for ${var.cluster_name}" # Human-readable name for the note
    }
  }
}

# Secret Manager for sensitive data (Optional, based on variable)
# Creates secrets and grants the GKE service account access
resource "google_secret_manager_secret" "secrets" {
  for_each = var.enable_secret_manager ? var.secrets : {} # Conditionally create secrets based on map variable

  secret_id = each.key # Use map key as secret ID
  project   = var.project_id

  replication {
    automatic = true # Automatically replicate secret data
  }
}

# Add secret versions with the actual secret data
resource "google_secret_manager_secret_version" "versions" {
  for_each = var.enable_secret_manager ? var.secrets : {} # Conditionally create secret versions

  secret      = google_secret_manager_secret.secrets[each.key].id # Reference the created secret
  secret_data = each.value # Use map value as secret data (sensitive)
}

# Allow GKE service account to access secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = var.enable_secret_manager ? var.secrets : {} # Conditionally grant access

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id # Reference the secret ID
  role      = "roles/secretmanager.secretAccessor" # Grant secret accessor role
  member    = "serviceAccount:${google_service_account.gke_sa.email}" # Grant to the GKE service account
}

# Org policy constraints (Optional, based on variable)
# Example: Disable serial port access on VMs for security
resource "google_org_policy_constraint" "constraint" {
  count = var.apply_org_policies ? 1 : 0 # Conditionally apply based on variable

  name = "compute.disableSerialPortAccess" # Name of the organization policy constraint

  boolean_constraint {
    enforced = true # Enforce the constraint
  }
}
