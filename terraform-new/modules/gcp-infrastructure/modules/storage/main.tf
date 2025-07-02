# =============================================================================
# CargoLynx TMS - Storage Module
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
# Application Storage Bucket
# =============================================================================

resource "google_storage_bucket" "app_storage" {
  name          = "${var.project_id}-${var.environment}-app-storage"
  location      = var.region
  project       = var.project_id
  force_destroy = var.environment == "local" ? true : false

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning
  versioning {
    enabled = var.enable_bucket_versioning
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age_nearline
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age_coldline
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age_archive
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.bucket_lifecycle_age_delete
    }
    action {
      type = "Delete"
    }
  }

  # Encryption
  encryption {
    default_kms_key_name = var.application_data_key_id
  }

  # CORS configuration for web access
  cors {
    origin          = ["https://${var.domain_name}", "https://*.${var.domain_name}"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Website configuration (if needed for static assets)
  dynamic "website" {
    for_each = var.enable_website_hosting ? [1] : []
    content {
      main_page_suffix = "index.html"
      not_found_page   = "404.html"
    }
  }

  # Labels
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    cost-center = var.cost_center
    purpose     = "application-storage"
  }

  depends_on = [
    var.apis_enabled
  ]
}

# =============================================================================
# Backup Storage Bucket
# =============================================================================

resource "google_storage_bucket" "backup_storage" {
  name          = "${var.project_id}-${var.environment}-backup-storage"
  location      = var.region
  project       = var.project_id
  force_destroy = var.environment == "local" ? true : false

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning (critical for backups)
  versioning {
    enabled = true
  }

  # Lifecycle management for backups
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Keep backups for 7 years (2555 days)
  lifecycle_rule {
    condition {
      age = 2555
    }
    action {
      type = "Delete"
    }
  }

  # Encryption
  encryption {
    default_kms_key_name = var.application_data_key_id
  }

  # Labels
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    cost-center = var.cost_center
    purpose     = "backup-storage"
  }

  depends_on = [
    var.apis_enabled
  ]
}

# =============================================================================
# Logs Storage Bucket
# =============================================================================

resource "google_storage_bucket" "logs_storage" {
  name          = "${var.project_id}-${var.environment}-logs-storage"
  location      = var.region
  project       = var.project_id
  force_destroy = var.environment == "local" ? true : false

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning (not needed for logs)
  versioning {
    enabled = false
  }

  # Lifecycle management for logs
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Delete logs after 90 days for cost optimization
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  # Encryption
  encryption {
    default_kms_key_name = var.application_data_key_id
  }

  # Labels
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    cost-center = var.cost_center
    purpose     = "logs-storage"
  }

  depends_on = [
    var.apis_enabled
  ]
}

# =============================================================================
# IAM for Storage Buckets
# =============================================================================

# App storage bucket access for GKE service account
resource "google_storage_bucket_iam_member" "app_storage_gke_access" {
  bucket = google_storage_bucket.app_storage.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gke_service_account_email}"
}

# Backup storage bucket access for GKE service account (read-only)
resource "google_storage_bucket_iam_member" "backup_storage_gke_access" {
  bucket = google_storage_bucket.backup_storage.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.gke_service_account_email}"
}

# Logs storage bucket access for GKE service account
resource "google_storage_bucket_iam_member" "logs_storage_gke_access" {
  bucket = google_storage_bucket.logs_storage.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.gke_service_account_email}"
}

# Terraform service account access to all buckets
resource "google_storage_bucket_iam_member" "terraform_app_storage_access" {
  bucket = google_storage_bucket.app_storage.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.terraform_service_account_email}"
}

resource "google_storage_bucket_iam_member" "terraform_backup_storage_access" {
  bucket = google_storage_bucket.backup_storage.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.terraform_service_account_email}"
}

resource "google_storage_bucket_iam_member" "terraform_logs_storage_access" {
  bucket = google_storage_bucket.logs_storage.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${var.terraform_service_account_email}"
}