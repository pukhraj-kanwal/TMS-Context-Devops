# =============================================================================
# CargoLynx TMS - Storage Module Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (local, development, staging, uat, production)"
  type        = string
}

variable "cost_center" {
  description = "Cost center for resource billing"
  type        = string
  default     = "engineering"
}

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
}

variable "application_data_key_id" {
  description = "The ID of the KMS key for application data encryption"
  type        = string
}

variable "gke_service_account_email" {
  description = "Email address of the GKE service account"
  type        = string
}

variable "terraform_service_account_email" {
  description = "Email address of the Terraform service account"
  type        = string
}

variable "enable_bucket_versioning" {
  description = "Enable versioning for Cloud Storage buckets"
  type        = bool
  default     = true
}

variable "bucket_lifecycle_age_nearline" {
  description = "Age in days before transitioning to Nearline storage"
  type        = number
  default     = 30
}

variable "bucket_lifecycle_age_coldline" {
  description = "Age in days before transitioning to Coldline storage"
  type        = number
  default     = 90
}

variable "bucket_lifecycle_age_archive" {
  description = "Age in days before transitioning to Archive storage"
  type        = number
  default     = 365
}

variable "bucket_lifecycle_age_delete" {
  description = "Age in days before deleting objects"
  type        = number
  default     = 2555
}

variable "enable_website_hosting" {
  description = "Enable static website hosting on the app storage bucket"
  type        = bool
  default     = false
}

variable "apis_enabled" {
  description = "Dependency marker for APIs being enabled"
  type        = any
  default     = null
}