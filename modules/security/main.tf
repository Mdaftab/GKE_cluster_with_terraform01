# modules/security/main.tf
#
# This module implements security best practices for GKE deployments:
# - Least privilege service account for GKE nodes
# - Binary Authorization (optional)
# - Security policies
# - VPC Service Controls (optional)
# - Project-level security settings

# Create dedicated service account for GKE nodes
resource "google_service_account" "gke_sa" {
  account_id   = var.service_account_id
  display_name = "GKE Service Account for ${var.cluster_name}"
  description  = "Service account for GKE nodes with minimal permissions"
  project      = var.project_id
}

# Grant minimum necessary permissions to the service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",               # Write logs
    "roles/monitoring.metricWriter",         # Write metrics
    "roles/monitoring.viewer",               # Read metrics
    "roles/stackdriver.resourceMetadata.writer", # Write resource metadata
    "roles/artifactregistry.reader",         # Pull images from Artifact Registry
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Security Policy (Cloud Armor) - Optional, based on variable
resource "google_compute_security_policy" "security_policy" {
  count = var.enable_cloud_armor ? 1 : 0
  
  name        = "${var.project_name}-security-policy"
  description = "Security policy for ${var.cluster_name}"

  # Block access from countries with high rates of attacks (example)
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "origin.region_code == 'RU' || origin.region_code == 'CN' || origin.region_code == 'IR' || origin.region_code == 'KP'"
      }
    }
    description = "Block access from high-risk countries"
  }

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = "1001"
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limiting"
  }

  # Default rule (required)
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule, higher priority overrides it"
  }
}

# Binary Authorization (Optional, based on variable)
resource "google_binary_authorization_policy" "policy" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project = var.project_id

  # Only allow images from approved repositories
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }

  admission_whitelist_patterns {
    name_pattern = "us-docker.pkg.dev/${var.project_id}/*"
  }

  # Required attestations
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.attestor[0].name,
    ]
  }

  # Add exemption for certified base images
  global_policy_evaluation_mode = "ENABLE"
}

# Binary Authorization Attestor (Created only if binary authorization is enabled)
resource "google_binary_authorization_attestor" "attestor" {
  count = var.enable_binary_authorization ? 1 : 0
  
  name = "${var.project_name}-attestor"
  attestation_authority_note {
    note_reference = google_container_analysis_note.note[0].name
    public_keys {
      id = "1"
      pkix_public_key {
        public_key_pem      = var.attestor_public_key
        signature_algorithm = "RSA_PSS_2048_SHA256"
      }
    }
  }
  project = var.project_id
}

# Binary Authorization Note
resource "google_container_analysis_note" "note" {
  count = var.enable_binary_authorization ? 1 : 0
  
  name    = "${var.project_name}-attestor-note"
  project = var.project_id

  attestation_authority {
    hint {
      human_readable_name = "Attestor for ${var.cluster_name}"
    }
  }
}

# Secret Manager for sensitive data (Optional, based on variable)
resource "google_secret_manager_secret" "secrets" {
  for_each = var.enable_secret_manager ? var.secrets : {}
  
  secret_id = each.key
  project   = var.project_id
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "versions" {
  for_each = var.enable_secret_manager ? var.secrets : {}
  
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}

# Allow GKE service account to access secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = var.enable_secret_manager ? var.secrets : {}
  
  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Org policy constraints (Optional, based on variable)
resource "google_org_policy_constraint" "constraint" {
  count = var.apply_org_policies ? 1 : 0
  
  name = "compute.disableSerialPortAccess"
  
  boolean_constraint {
    enforced = true
  }
}