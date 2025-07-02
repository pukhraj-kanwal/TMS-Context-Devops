# =============================================================================
# CargoLynx TMS - Networking Module Variables
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

variable "apis_enabled" {
  description = "Dependency marker for APIs being enabled"
  type        = any
  default     = null
}