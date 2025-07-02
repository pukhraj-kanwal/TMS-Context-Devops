# =============================================================================
# CargoLynx TMS - Monitoring Module Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Core Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (local, development, staging, uat, production)"
  type        = string
  
  validation {
    condition = contains(["local", "development", "staging", "uat", "production"], var.environment)
    error_message = "Environment must be one of: local, development, staging, uat, production."
  }
}

variable "region" {
  description = "The GCP region for monitoring resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for monitoring resources"
  type        = string
  default     = "us-central1-a"
}

# =============================================================================
# Notification Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
}

variable "alert_phone_number" {
  description = "Phone number for SMS alerts (production only)"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel for notifications"
  type        = string
  default     = "#alerts"
}

variable "enable_email_notifications" {
  description = "Enable email notifications"
  type        = bool
  default     = true
}

variable "enable_sms_notifications" {
  description = "Enable SMS notifications"
  type        = bool
  default     = false
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications"
  type        = bool
  default     = false
}

# =============================================================================
# Uptime Check Configuration
# =============================================================================

variable "enable_uptime_checks" {
  description = "Enable uptime monitoring checks"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "Application port for uptime checks"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/health"
}

variable "uptime_check_timeout" {
  description = "Uptime check timeout in seconds"
  type        = number
  default     = 10
}

variable "uptime_check_period" {
  description = "Uptime check period in seconds"
  type        = number
  default     = 300
}

variable "uptime_check_content_matcher" {
  description = "Content to match in uptime checks"
  type        = string
  default     = "OK"
}

variable "uptime_check_regions" {
  description = "Regions for uptime checks"
  type        = list(string)
  default     = ["us-central1", "us-east1", "europe-west1"]
}

variable "uptime_auth_required" {
  description = "Whether uptime checks require authentication"
  type        = bool
  default     = false
}

variable "uptime_auth_username" {
  description = "Username for uptime check authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "uptime_auth_password" {
  description = "Password for uptime check authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# Infrastructure Monitoring
# =============================================================================

variable "gke_cluster_name" {
  description = "Name of the GKE cluster to monitor"
  type        = string
}

variable "database_instance_name" {
  description = "Name of the database instance to monitor"
  type        = string
}

variable "enable_database_monitoring" {
  description = "Enable database-specific monitoring"
  type        = bool
  default     = true
}

# =============================================================================
# Alert Thresholds
# =============================================================================

variable "enable_cpu_alerts" {
  description = "Enable CPU usage alerts"
  type        = bool
  default     = true
}

variable "cpu_threshold_percent" {
  description = "CPU usage threshold percentage for alerts"
  type        = number
  default     = 80
  
  validation {
    condition     = var.cpu_threshold_percent > 0 && var.cpu_threshold_percent <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "enable_memory_alerts" {
  description = "Enable memory usage alerts"
  type        = bool
  default     = true
}

variable "memory_threshold_percent" {
  description = "Memory usage threshold percentage for alerts"
  type        = number
  default     = 85
  
  validation {
    condition     = var.memory_threshold_percent > 0 && var.memory_threshold_percent <= 100
    error_message = "Memory threshold must be between 1 and 100."
  }
}

variable "db_connection_threshold" {
  description = "Database connection threshold for alerts"
  type        = number
  default     = 80
}

variable "enable_error_rate_alerts" {
  description = "Enable application error rate alerts"
  type        = bool
  default     = true
}

variable "error_rate_threshold" {
  description = "Error rate threshold percentage for alerts"
  type        = number
  default     = 5
  
  validation {
    condition     = var.error_rate_threshold >= 0 && var.error_rate_threshold <= 100
    error_message = "Error rate threshold must be between 0 and 100."
  }
}

variable "alert_duration" {
  description = "Duration in seconds before triggering alerts"
  type        = number
  default     = 300
}

# =============================================================================
# Log Monitoring
# =============================================================================

variable "enable_log_metrics" {
  description = "Enable log-based metrics"
  type        = bool
  default     = true
}

variable "slow_query_threshold" {
  description = "Slow query threshold in seconds"
  type        = number
  default     = 5
}

# =============================================================================
# Environment-Specific Configuration
# =============================================================================

variable "monitoring_tier" {
  description = "Monitoring tier based on environment"
  type        = string
  default     = "basic"
  
  validation {
    condition = contains(["minimal", "basic", "standard", "comprehensive"], var.monitoring_tier)
    error_message = "Monitoring tier must be one of: minimal, basic, standard, comprehensive."
  }
}

variable "retention_days" {
  description = "Data retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 3653
    error_message = "Retention days must be between 1 and 3653 (10 years)."
  }
}

# =============================================================================
# Cost Optimization
# =============================================================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring (may incur additional costs)"
  type        = bool
  default     = false
}

variable "sample_rate" {
  description = "Sampling rate for metrics (1.0 = 100%, 0.1 = 10%)"
  type        = number
  default     = 1.0
  
  validation {
    condition     = var.sample_rate > 0 && var.sample_rate <= 1.0
    error_message = "Sample rate must be between 0.1 and 1.0."
  }
}

# =============================================================================
# Dashboard Configuration
# =============================================================================

variable "enable_custom_dashboards" {
  description = "Enable custom monitoring dashboards"
  type        = bool
  default     = true
}

variable "dashboard_time_range" {
  description = "Default time range for dashboards"
  type        = string
  default     = "1h"
  
  validation {
    condition = contains(["1h", "6h", "12h", "1d", "7d", "30d"], var.dashboard_time_range)
    error_message = "Dashboard time range must be one of: 1h, 6h, 12h, 1d, 7d, 30d."
  }
}