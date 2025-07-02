# =============================================================================
# CargoLynx TMS - Security Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Service Account Outputs
# =============================================================================

output "gke_service_account_id" {
  description = "The ID of the GKE service account"
  value       = google_service_account.gke_service_account.id
}

output "gke_service_account_email" {
  description = "The email address of the GKE service account"
  value       = google_service_account.gke_service_account.email
}

output "gke_service_account_name" {
  description = "The name of the GKE service account"
  value       = google_service_account.gke_service_account.name
}

output "terraform_service_account_id" {
  description = "The ID of the Terraform service account"
  value       = google_service_account.terraform_service_account.id
}

output "terraform_service_account_email" {
  description = "The email address of the Terraform service account"
  value       = google_service_account.terraform_service_account.email
}

output "terraform_service_account_name" {
  description = "The name of the Terraform service account"
  value       = google_service_account.terraform_service_account.name
}

# =============================================================================
# KMS Outputs
# =============================================================================

output "kms_key_ring_id" {
  description = "The ID of the KMS key ring"
  value       = google_kms_key_ring.key_ring.id
}

output "kms_key_ring_name" {
  description = "The name of the KMS key ring"
  value       = google_kms_key_ring.key_ring.name
}

output "terraform_state_key_id" {
  description = "The ID of the Terraform state encryption key"
  value       = google_kms_crypto_key.terraform_state_key.id
}

output "terraform_state_key_name" {
  description = "The name of the Terraform state encryption key"
  value       = google_kms_crypto_key.terraform_state_key.name
}

output "application_data_key_id" {
  description = "The ID of the application data encryption key"
  value       = google_kms_crypto_key.application_data_key.id
}

output "application_data_key_name" {
  description = "The name of the application data encryption key"
  value       = google_kms_crypto_key.application_data_key.name
}

# =============================================================================
# Security Summary
# =============================================================================

output "security_summary" {
  description = "Summary of security configuration"
  value = {
    environment = var.environment
    service_accounts = {
      gke_sa = {
        id    = google_service_account.gke_service_account.id
        email = google_service_account.gke_service_account.email
      }
      terraform_sa = {
        id    = google_service_account.terraform_service_account.id
        email = google_service_account.terraform_service_account.email
      }
    }
    kms = {
      key_ring_name         = google_kms_key_ring.key_ring.name
      terraform_state_key   = google_kms_crypto_key.terraform_state_key.name
      application_data_key  = google_kms_crypto_key.application_data_key.name
    }
    workload_identity_enabled = true
  }
}