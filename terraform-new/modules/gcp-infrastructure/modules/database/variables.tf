# =============================================================================
# CargoLynx TMS - Database Module Variables
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

variable "vpc_network_id" {
  description = "The ID of the VPC network for private networking"
  type        = string
}

variable "private_vpc_connection" {
  description = "The private VPC connection for Cloud SQL"
  type        = any
}

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
  description = "Password for the main database user"
  type        = string
  sensitive   = true
}

variable "readonly_database_password" {
  description = "Password for the read-only database user"
  type        = string
  sensitive   = true
}

variable "apis_enabled" {
  description = "Dependency marker for APIs being enabled"
  type        = any
  default     = null
}