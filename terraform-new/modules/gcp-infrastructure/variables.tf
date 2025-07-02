# =============================================================================
# CargoLynx TMS - GCP Infrastructure Module Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Core Configuration
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
  
  validation {
    condition     = contains(["local", "development", "staging", "uat", "production"], var.environment)
    error_message = "Environment must be one of: local, development, staging, uat, production."
  }
}

variable "cost_center" {
  description = "Cost center for resource billing"
  type        = string
  default     = "engineering"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
}

variable "database_subnet_cidr" {
  description = "CIDR range for database subnet"
  type        = string
}

# =============================================================================
# GKE Configuration
# =============================================================================

variable "enable_gke_autopilot" {
  description = "Enable GKE Autopilot mode for simplified management"
  type        = bool
  default     = false
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}

variable "gke_node_disk_size" {
  description = "Disk size for GKE nodes in GB"
  type        = number
}

variable "gke_node_count" {
  description = "Initial number of nodes in the GKE node pool"
  type        = number
}

variable "gke_min_nodes" {
  description = "Minimum number of nodes in the GKE node pool"
  type        = number
}

variable "gke_max_nodes" {
  description = "Maximum number of nodes in the GKE node pool"
  type        = number
}

variable "preemptible_node_pool" {
  description = "Enable preemptible node pool for cost savings"
  type        = bool
}

variable "spot_node_pool" {
  description = "Enable spot instance node pool for cost savings"
  type        = bool
}

variable "gke_node_taints" {
  description = "List of taints to apply to GKE nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "database_version" {
  description = "PostgreSQL version for Cloud SQL"
  type        = string
}

variable "database_tier" {
  description = "Machine type for Cloud SQL instance"
  type        = string
}

variable "database_disk_size" {
  description = "Disk size for Cloud SQL instance in GB"
  type        = number
}

variable "database_max_disk_size" {
  description = "Maximum disk size for auto-resize in GB"
  type        = number
}

variable "database_availability_type" {
  description = "Availability type for Cloud SQL (ZONAL or REGIONAL)"
  type        = string
}

variable "database_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL instance"
  type        = bool
}

variable "database_password" {
  description = "Password for the database user"
  type        = string
  sensitive   = true
}

variable "readonly_database_password" {
  description = "Password for the read-only database user"
  type        = string
  sensitive   = true
  default     = "readonly-dev-123"
}

# =============================================================================
# Storage Configuration
# =============================================================================

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

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
}

# =============================================================================
# Monitoring Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}