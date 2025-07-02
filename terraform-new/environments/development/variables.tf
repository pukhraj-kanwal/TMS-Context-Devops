# =============================================================================
# CargoLynx TMS - Development Environment Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Core Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID for development workloads"
  type        = string
}

variable "region" {
  description = "The GCP region for development resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for development resources"
  type        = string
  default     = "us-central1-a"
}

variable "terraform_state_bucket" {
  description = "GCS bucket for Terraform state storage"
  type        = string
}

# =============================================================================
# Domain Configuration
# =============================================================================

variable "domain_name" {
  description = "Development domain name (e.g., dev.example.com)"
  type        = string
}

# =============================================================================
# Monitoring and Alerting Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for development alerts"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for development notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel for development alerts"
  type        = string
  default     = "#dev-alerts"
}

# =============================================================================
# Cost Optimization Configuration
# =============================================================================

variable "enable_auto_shutdown" {
  description = "Enable automatic shutdown during non-business hours"
  type        = bool
  default     = true
}

variable "shutdown_schedule" {
  description = "Cron schedule for auto-shutdown (UTC)"
  type        = string
  default     = "0 22 * * 1-5"  # 10 PM weekdays
  
  validation {
    condition     = can(regex("^[0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+$", var.shutdown_schedule))
    error_message = "Shutdown schedule must be a valid cron expression."
  }
}

variable "startup_schedule" {
  description = "Cron schedule for auto-startup (UTC)"
  type        = string
  default     = "0 8 * * 1-5"   # 8 AM weekdays
  
  validation {
    condition     = can(regex("^[0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+ [0-9*,/-]+$", var.startup_schedule))
    error_message = "Startup schedule must be a valid cron expression."
  }
}

variable "max_daily_cost_usd" {
  description = "Maximum daily cost limit for development environment"
  type        = number
  default     = 50
  
  validation {
    condition     = var.max_daily_cost_usd > 0 && var.max_daily_cost_usd <= 1000
    error_message = "Max daily cost must be between $1 and $1000."
  }
}

variable "enable_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = true
}

# =============================================================================
# Development Features Configuration
# =============================================================================

variable "enable_debug_logging" {
  description = "Enable enhanced debug logging for development"
  type        = bool
  default     = true
}

variable "enable_development_tools" {
  description = "Enable additional development and debugging tools"
  type        = bool
  default     = true
}

variable "enable_hot_reload" {
  description = "Enable hot reload capabilities for faster development"
  type        = bool
  default     = true
}

variable "enable_local_testing" {
  description = "Enable local testing integrations"
  type        = bool
  default     = true
}

# =============================================================================
# Security Configuration
# =============================================================================

variable "developer_access_cidrs" {
  description = "CIDR blocks for developer access to the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Should be restricted to office/VPN IPs
}

variable "enable_developer_access" {
  description = "Enable developer access to cluster resources"
  type        = bool
  default     = true
}

variable "developer_service_accounts" {
  description = "List of developer service accounts for cluster access"
  type        = list(string)
  default     = []
}

# =============================================================================
# Testing Configuration
# =============================================================================

variable "enable_integration_testing" {
  description = "Enable integration testing capabilities"
  type        = bool
  default     = true
}

variable "enable_load_testing" {
  description = "Enable load testing capabilities"
  type        = bool
  default     = false
}

variable "enable_security_testing" {
  description = "Enable security testing tools"
  type        = bool
  default     = true
}

variable "test_data_retention_days" {
  description = "Number of days to retain test data"
  type        = number
  default     = 7
  
  validation {
    condition     = var.test_data_retention_days >= 1 && var.test_data_retention_days <= 30
    error_message = "Test data retention must be between 1 and 30 days."
  }
}

# =============================================================================
# Backup and Recovery Configuration
# =============================================================================

variable "backup_frequency" {
  description = "Backup frequency for development environment"
  type        = string
  default     = "weekly"
  
  validation {
    condition = contains(["daily", "weekly", "monthly"], var.backup_frequency)
    error_message = "Backup frequency must be one of: daily, weekly, monthly."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

# =============================================================================
# Performance Configuration
# =============================================================================

variable "performance_tier" {
  description = "Performance tier for development workloads"
  type        = string
  default     = "balanced"
  
  validation {
    condition = contains(["minimal", "balanced", "standard"], var.performance_tier)
    error_message = "Performance tier must be one of: minimal, balanced, standard."
  }
}

variable "enable_horizontal_scaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "enable_vertical_scaling" {
  description = "Enable vertical pod autoscaling"
  type        = bool
  default     = false
}

# =============================================================================
# CI/CD Integration Configuration
# =============================================================================

variable "ci_cd_integration" {
  description = "CI/CD integration configuration"
  type = object({
    github_webhook_secret   = optional(string, "")
    gitlab_webhook_secret   = optional(string, "")
    jenkins_webhook_secret  = optional(string, "")
    enable_auto_deployment  = optional(bool, true)
  })
  default = {}
  sensitive = true
}

variable "deployment_strategy" {
  description = "Deployment strategy for development environment"
  type        = string
  default     = "rolling"
  
  validation {
    condition = contains(["rolling", "recreate", "blue-green", "canary"], var.deployment_strategy)
    error_message = "Deployment strategy must be one of: rolling, recreate, blue-green, canary."
  }
}

# =============================================================================
# Monitoring Configuration
# =============================================================================

variable "monitoring_level" {
  description = "Level of monitoring for development environment"
  type        = string
  default     = "standard"
  
  validation {
    condition = contains(["minimal", "standard", "detailed"], var.monitoring_level)
    error_message = "Monitoring level must be one of: minimal, standard, detailed."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 7 && var.log_retention_days <= 365
    error_message = "Log retention must be between 7 and 365 days."
  }
}

variable "enable_metrics_collection" {
  description = "Enable detailed metrics collection"
  type        = bool
  default     = true
}

# =============================================================================
# Environment Isolation Configuration
# =============================================================================

variable "isolation_level" {
  description = "Level of isolation from other environments"
  type        = string
  default     = "standard"
  
  validation {
    condition = contains(["minimal", "standard", "strict"], var.isolation_level)
    error_message = "Isolation level must be one of: minimal, standard, strict."
  }
}

variable "enable_cross_environment_access" {
  description = "Enable access to other environments (staging, production)"
  type        = bool
  default     = false
}

# =============================================================================
# Development Team Configuration
# =============================================================================

variable "development_teams" {
  description = "Configuration for development teams"
  type = map(object({
    team_lead_email     = string
    team_members       = list(string)
    resource_quota     = optional(string, "medium")
    namespace_prefix   = optional(string, "")
  }))
  default = {}
}

variable "enable_multi_tenancy" {
  description = "Enable multi-tenant capabilities for multiple teams"
  type        = bool
  default     = false
}