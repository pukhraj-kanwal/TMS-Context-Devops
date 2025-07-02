# =============================================================================
# CargoLynx TMS - Storage Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Application Storage Outputs
# =============================================================================

output "app_storage_bucket_name" {
  description = "The name of the application storage bucket"
  value       = google_storage_bucket.app_storage.name
}

output "app_storage_bucket_url" {
  description = "The URL of the application storage bucket"
  value       = google_storage_bucket.app_storage.url
}

output "app_storage_bucket_self_link" {
  description = "The self-link of the application storage bucket"
  value       = google_storage_bucket.app_storage.self_link
}

# =============================================================================
# Backup Storage Outputs
# =============================================================================

output "backup_storage_bucket_name" {
  description = "The name of the backup storage bucket"
  value       = google_storage_bucket.backup_storage.name
}

output "backup_storage_bucket_url" {
  description = "The URL of the backup storage bucket"
  value       = google_storage_bucket.backup_storage.url
}

output "backup_storage_bucket_self_link" {
  description = "The self-link of the backup storage bucket"
  value       = google_storage_bucket.backup_storage.self_link
}

# =============================================================================
# Logs Storage Outputs
# =============================================================================

output "logs_storage_bucket_name" {
  description = "The name of the logs storage bucket"
  value       = google_storage_bucket.logs_storage.name
}

output "logs_storage_bucket_url" {
  description = "The URL of the logs storage bucket"
  value       = google_storage_bucket.logs_storage.url
}

output "logs_storage_bucket_self_link" {
  description = "The self-link of the logs storage bucket"
  value       = google_storage_bucket.logs_storage.self_link
}

# =============================================================================
# Storage Configuration Outputs
# =============================================================================

output "storage_encryption_key" {
  description = "The KMS key used for storage encryption"
  value       = var.application_data_key_id
}

output "bucket_locations" {
  description = "Locations of all storage buckets"
  value = {
    app_storage    = google_storage_bucket.app_storage.location
    backup_storage = google_storage_bucket.backup_storage.location
    logs_storage   = google_storage_bucket.logs_storage.location
  }
}

# =============================================================================
# Access Control Outputs
# =============================================================================

output "storage_iam_members" {
  description = "IAM members with access to storage buckets"
  value = {
    app_storage = {
      gke_access       = google_storage_bucket_iam_member.app_storage_gke_access.member
      terraform_access = google_storage_bucket_iam_member.terraform_app_storage_access.member
    }
    backup_storage = {
      gke_access       = google_storage_bucket_iam_member.backup_storage_gke_access.member
      terraform_access = google_storage_bucket_iam_member.terraform_backup_storage_access.member
    }
    logs_storage = {
      gke_access       = google_storage_bucket_iam_member.logs_storage_gke_access.member
      terraform_access = google_storage_bucket_iam_member.terraform_logs_storage_access.member
    }
  }
}

# =============================================================================
# Storage Summary
# =============================================================================

output "storage_summary" {
  description = "Summary of storage configuration"
  value = {
    environment = var.environment
    region      = var.region
    buckets = {
      app_storage = {
        name         = google_storage_bucket.app_storage.name
        url          = google_storage_bucket.app_storage.url
        versioning   = var.enable_bucket_versioning
        encryption   = true
        lifecycle_management = true
      }
      backup_storage = {
        name         = google_storage_bucket.backup_storage.name
        url          = google_storage_bucket.backup_storage.url
        versioning   = true
        encryption   = true
        lifecycle_management = true
        retention_years = 7
      }
      logs_storage = {
        name         = google_storage_bucket.logs_storage.name
        url          = google_storage_bucket.logs_storage.url
        versioning   = false
        encryption   = true
        lifecycle_management = true
        retention_days = 90
      }
    }
    features = {
      kms_encryption      = true
      uniform_access      = true
      cors_enabled        = true
      website_hosting     = var.enable_website_hosting
      lifecycle_policies  = true
    }
    access_control = {
      gke_service_account       = var.gke_service_account_email
      terraform_service_account = var.terraform_service_account_email
    }
  }
}

# =============================================================================
# Storage URLs for Applications
# =============================================================================

output "storage_endpoints" {
  description = "Storage endpoints for application configuration"
  value = {
    app_storage_endpoint    = "gs://${google_storage_bucket.app_storage.name}"
    backup_storage_endpoint = "gs://${google_storage_bucket.backup_storage.name}"
    logs_storage_endpoint   = "gs://${google_storage_bucket.logs_storage.name}"
    domain_cors_origins     = ["https://${var.domain_name}", "https://*.${var.domain_name}"]
  }
}