# =============================================================================
# CargoLynx TMS - Local Environment Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Core Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID for local development"
  type        = string
}

variable "region" {
  description = "The GCP region for local development resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for local development resources"
  type        = string
  default     = "us-central1-a"
}

# =============================================================================
# Domain Configuration
# =============================================================================

variable "domain_name" {
  description = "Domain name for local development (can be localhost or dev domain)"
  type        = string
  default     = "localhost"
}

# =============================================================================
# Monitoring Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for development alerts"
  type        = string
}

# =============================================================================
# Local Development Overrides
# =============================================================================

variable "enable_debug_mode" {
  description = "Enable debug mode for local development"
  type        = bool
  default     = true
}

variable "skip_deletion_protection" {
  description = "Skip deletion protection for easier cleanup during development"
  type        = bool
  default     = true
}

variable "auto_shutdown_enabled" {
  description = "Enable automatic shutdown for cost savings"
  type        = bool
  default     = true
}

variable "max_daily_cost_usd" {
  description = "Maximum daily cost limit for local environment"
  type        = number
  default     = 5
}