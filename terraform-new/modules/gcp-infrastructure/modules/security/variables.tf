# =============================================================================
# CargoLynx TMS - Security Module Variables
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

variable "apis_enabled" {
  description = "Dependency marker for APIs being enabled"
  type        = any
  default     = null
}