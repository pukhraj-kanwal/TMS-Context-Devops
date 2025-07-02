# =============================================================================
# CargoLynx TMS - Security Module
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# =============================================================================
# Service Accounts
# =============================================================================

# Service account for GKE cluster and workloads
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.environment}-gke-sa"
  display_name = "GKE Service Account for ${var.environment}"
  description  = "Service account for GKE cluster and workloads in ${var.environment} environment"
  project      = var.project_id
}

# Service account for Terraform operations
resource "google_service_account" "terraform_service_account" {
  account_id   = "${var.environment}-terraform-sa"
  display_name = "Terraform Service Account for ${var.environment}"
  description  = "Service account for Terraform infrastructure operations in ${var.environment} environment"
  project      = var.project_id
}

# =============================================================================
# IAM Role Bindings for GKE Service Account
# =============================================================================

# Basic roles for GKE node functionality
resource "google_project_iam_member" "gke_worker_role" {
  project = var.project_id
  role    = "roles/container.nodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_project_iam_member" "gke_registry_reader" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_project_iam_member" "gke_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

resource "google_project_iam_member" "gke_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Cloud SQL client access for applications
resource "google_project_iam_member" "gke_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# KMS access for application data encryption
resource "google_project_iam_member" "gke_kms_user" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# =============================================================================
# IAM Role Bindings for Terraform Service Account
# =============================================================================

# Core compute and networking permissions
resource "google_project_iam_member" "terraform_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

resource "google_project_iam_member" "terraform_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

resource "google_project_iam_member" "terraform_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

resource "google_project_iam_member" "terraform_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

resource "google_project_iam_member" "terraform_iam_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

resource "google_project_iam_member" "terraform_kms_admin" {
  project = var.project_id
  role    = "roles/cloudkms.admin"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

# =============================================================================
# KMS Key Ring and Keys
# =============================================================================

# KMS Key Ring for environment encryption keys
resource "google_kms_key_ring" "key_ring" {
  name     = "${var.environment}-key-ring"
  location = var.region
  project  = var.project_id

  depends_on = [
    var.apis_enabled
  ]
}

# KMS key for Terraform state encryption
resource "google_kms_crypto_key" "terraform_state_key" {
  name            = "${var.environment}-terraform-state-key"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# KMS key for application data encryption
resource "google_kms_crypto_key" "application_data_key" {
  name            = "${var.environment}-application-data-key"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "7776000s" # 90 days

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# Workload Identity Binding
# =============================================================================

# Enable Workload Identity for GKE service account
resource "google_service_account_iam_member" "gke_workload_identity_binding" {
  service_account_id = google_service_account.gke_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/gke-workload-identity]"
}