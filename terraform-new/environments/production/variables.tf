# =============================================================================
# CargoLynx TMS - Production Environment Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Core Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID for production workloads"
  type        = string
}

variable "region" {
  description = "The GCP region for production resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for production resources"
  type        = string
  default     = "us-central1-a"
}

variable "terraform_state_bucket" {
  description = "GCS bucket for Terraform state storage"
  type        = string
}

# =============================================================================
# Domain and SSL Configuration
# =============================================================================

variable "domain_name" {
  description = "Production domain name"
  type        = string
}

variable "ssl_certificate_domains" {
  description = "Additional domains for SSL certificates"
  type        = list(string)
  default     = []
}

# =============================================================================
# Monitoring and Alerting Configuration
# =============================================================================

variable "alert_email" {
  description = "Primary email for production alerts"
  type        = string
}

variable "alert_phone_number" {
  description = "Phone number for critical SMS alerts"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for production notifications"
  type        = string
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel for production alerts"
  type        = string
  default     = "#production-alerts"
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key for critical alerts"
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# Security Configuration
# =============================================================================

variable "authorized_networks" {
  description = "CIDR blocks authorized to access the cluster"
  type        = list(string)
  default     = []
}

variable "security_admin_email" {
  description = "Security administrator email for compliance notifications"
  type        = string
}

variable "enable_security_scanning" {
  description = "Enable comprehensive security scanning"
  type        = bool
  default     = true
}

variable "compliance_framework" {
  description = "Compliance framework requirements (SOC2, HIPAA, etc.)"
  type        = string
  default     = "SOC2_TYPE2"
  
  validation {
    condition = contains(["SOC2_TYPE2", "HIPAA", "PCI_DSS", "ISO_27001"], var.compliance_framework)
    error_message = "Compliance framework must be one of: SOC2_TYPE2, HIPAA, PCI_DSS, ISO_27001."
  }
}

# =============================================================================
# Backup and Recovery Configuration
# =============================================================================

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 365
  
  validation {
    condition     = var.backup_retention_days >= 30 && var.backup_retention_days <= 3653
    error_message = "Backup retention must be between 30 days and 10 years."
  }
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_region" {
  description = "Secondary region for cross-region backups"
  type        = string
  default     = "us-east1"
}

# =============================================================================
# Performance and Scaling Configuration
# =============================================================================

variable "performance_tier" {
  description = "Performance tier for production workloads"
  type        = string
  default     = "high"
  
  validation {
    condition = contains(["standard", "high", "premium"], var.performance_tier)
    error_message = "Performance tier must be one of: standard, high, premium."
  }
}

variable "max_surge_percentage" {
  description = "Maximum surge percentage for rolling updates"
  type        = number
  default     = 25
  
  validation {
    condition     = var.max_surge_percentage >= 0 && var.max_surge_percentage <= 100
    error_message = "Max surge percentage must be between 0 and 100."
  }
}

variable "max_unavailable_percentage" {
  description = "Maximum unavailable percentage during updates"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_unavailable_percentage >= 0 && var.max_unavailable_percentage <= 50
    error_message = "Max unavailable percentage must be between 0 and 50."
  }
}

# =============================================================================
# Cost Management
# =============================================================================

variable "budget_amount_usd" {
  description = "Monthly budget amount in USD for cost monitoring"
  type        = number
  default     = 5000
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [50, 75, 90, 100]
}

variable "enable_committed_use_discounts" {
  description = "Enable committed use discounts for cost optimization"
  type        = bool
  default     = true
}

# =============================================================================
# Network Security Configuration
# =============================================================================

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed for ingress traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Should be restricted in production
}

variable "enable_private_google_access" {
  description = "Enable private Google API access"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs for security monitoring"
  type        = bool
  default     = true
}

# =============================================================================
# Maintenance and Updates
# =============================================================================

variable "maintenance_window_start" {
  description = "Maintenance window start time (UTC)"
  type        = string
  default     = "02:00"
  
  validation {
    condition     = can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_window_start))
    error_message = "Maintenance window start must be in HH:MM format."
  }
}

variable "maintenance_window_duration" {
  description = "Maintenance window duration in hours"
  type        = number
  default     = 4
  
  validation {
    condition     = var.maintenance_window_duration >= 1 && var.maintenance_window_duration <= 8
    error_message = "Maintenance window duration must be between 1 and 8 hours."
  }
}

variable "auto_upgrade_channel" {
  description = "GKE auto-upgrade channel"
  type        = string
  default     = "STABLE"
  
  validation {
    condition = contains(["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"], var.auto_upgrade_channel)
    error_message = "Auto upgrade channel must be one of: RAPID, REGULAR, STABLE, UNSPECIFIED."
  }
}

# =============================================================================
# Disaster Recovery Configuration
# =============================================================================

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery capabilities"
  type        = bool
  default     = true
}

variable "rpo_hours" {
  description = "Recovery Point Objective in hours"
  type        = number
  default     = 1
  
  validation {
    condition     = var.rpo_hours >= 1 && var.rpo_hours <= 24
    error_message = "RPO must be between 1 and 24 hours."
  }
}

variable "rto_hours" {
  description = "Recovery Time Objective in hours"
  type        = number
  default     = 4
  
  validation {
    condition     = var.rto_hours >= 1 && var.rto_hours <= 72
    error_message = "RTO must be between 1 and 72 hours."
  }
}

# =============================================================================
# Integration Configuration
# =============================================================================

variable "external_integrations" {
  description = "External service integrations"
  type = object({
    datadog_api_key     = optional(string, "")
    newrelic_license    = optional(string, "")
    splunk_endpoint     = optional(string, "")
    auth0_domain        = optional(string, "")
  })
  default = {}
  sensitive = true
}

# =============================================================================
# Feature Flags
# =============================================================================

variable "feature_flags" {
  description = "Production feature flags"
  type = object({
    enable_canary_deployments    = optional(bool, true)
    enable_blue_green_deployments = optional(bool, true)
    enable_chaos_engineering     = optional(bool, false)
    enable_load_testing         = optional(bool, true)
    enable_security_policies    = optional(bool, true)
  })
  default = {}
}