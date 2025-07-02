# CargoLynx TMS - Staging Environment Variables
# Production-like configuration with cost optimizations for final validation

# Basic project configuration
variable "project_id" {
  description = "GCP project ID for staging environment"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with letter, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "GCP region for staging resources"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-west1", "us-west2",
      "europe-west1", "europe-west2", "europe-west3",
      "asia-southeast1", "asia-northeast1"
    ], var.region)
    error_message = "Region must be a valid GCP region."
  }
}

# Domain and SSL configuration
variable "staging_domain" {
  description = "Domain name for staging environment"
  type        = string
  default     = "staging.cargolynx.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.staging_domain))
    error_message = "Domain must be a valid domain name format."
  }
}

# Notification configuration
variable "notification_channels" {
  description = "List of notification channel configurations for staging alerts"
  type = list(object({
    type        = string
    destination = string
    enabled     = bool
  }))
  default = [
    {
      type        = "email"
      destination = "staging-alerts@cargolynx.com"
      enabled     = true
    },
    {
      type        = "slack"
      destination = "#staging-alerts"
      enabled     = true
    }
  ]
}

variable "alert_email" {
  description = "Primary email for staging environment alerts"
  type        = string
  default     = "staging-alerts@cargolynx.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for staging notifications (should be stored in secret manager)"
  type        = string
  default     = ""
  sensitive   = true
}

# Team and access configuration
variable "staging_team_members" {
  description = "List of team members with staging environment access"
  type = list(object({
    email = string
    role  = string
  }))
  default = [
    {
      email = "devops@cargolynx.com"
      role  = "roles/owner"
    },
    {
      email = "qa-team@cargolynx.com"
      role  = "roles/editor"
    },
    {
      email = "dev-team@cargolynx.com"
      role  = "roles/viewer"
    }
  ]
}

# CI/CD integration
variable "cicd_service_account" {
  description = "Service account email for CI/CD pipeline integration"
  type        = string
  default     = ""
  validation {
    condition = var.cicd_service_account == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.iam\\.gserviceaccount\\.com$", var.cicd_service_account))
    error_message = "CI/CD service account must be empty or a valid GCP service account email."
  }
}

variable "enable_cicd_triggers" {
  description = "Enable CI/CD triggers for staging deployments"
  type        = bool
  default     = true
}

variable "cicd_trigger_branches" {
  description = "Git branches that trigger staging deployments"
  type        = list(string)
  default     = ["develop", "staging", "release/*"]
}

# Testing and validation configuration
variable "enable_chaos_testing" {
  description = "Enable chaos engineering testing in staging"
  type        = bool
  default     = false
}

variable "enable_load_testing" {
  description = "Enable automated load testing resources"
  type        = bool
  default     = true
}

variable "load_testing_config" {
  description = "Configuration for load testing in staging"
  type = object({
    max_concurrent_users = number
    test_duration_minutes = number
    ramp_up_time_minutes = number
    target_endpoints = list(string)
  })
  default = {
    max_concurrent_users = 100
    test_duration_minutes = 15
    ramp_up_time_minutes = 5
    target_endpoints = ["/api/health", "/api/shipments", "/api/tracking"]
  }
}

variable "enable_synthetic_monitoring" {
  description = "Enable synthetic monitoring for staging environment"
  type        = bool
  default     = true
}

variable "synthetic_tests" {
  description = "Configuration for synthetic monitoring tests"
  type = list(object({
    name        = string
    url         = string
    method      = string
    frequency   = string
    timeout     = string
    regions     = list(string)
  }))
  default = [
    {
      name      = "API Health Check"
      url       = "/api/health"
      method    = "GET"
      frequency = "60s"
      timeout   = "10s"
      regions   = ["us-central1", "us-east1"]
    },
    {
      name      = "User Login Flow"
      url       = "/auth/login"
      method    = "POST"
      frequency = "300s"
      timeout   = "30s"
      regions   = ["us-central1"]
    }
  ]
}

# Security configuration
variable "enable_security_scanning" {
  description = "Enable security vulnerability scanning"
  type        = bool
  default     = true
}

variable "security_scan_schedule" {
  description = "Cron schedule for security scanning"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM
  validation {
    condition     = can(regex("^[0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+$", var.security_scan_schedule))
    error_message = "Security scan schedule must be a valid cron expression."
  }
}

variable "enable_compliance_monitoring" {
  description = "Enable compliance monitoring for staging environment"
  type        = bool
  default     = true
}

variable "compliance_frameworks" {
  description = "List of compliance frameworks to monitor"
  type        = list(string)
  default     = ["SOC2", "GDPR", "CCPA"]
  validation {
    condition = alltrue([
      for framework in var.compliance_frameworks : 
      contains(["SOC2", "GDPR", "CCPA", "HIPAA", "PCI-DSS"], framework)
    ])
    error_message = "Compliance frameworks must be from supported list: SOC2, GDPR, CCPA, HIPAA, PCI-DSS."
  }
}

# Data management
variable "enable_test_data_management" {
  description = "Enable automated test data management"
  type        = bool
  default     = true
}

variable "test_data_config" {
  description = "Configuration for test data management"
  type = object({
    enable_data_masking     = bool
    enable_synthetic_data   = bool
    data_retention_days     = number
    enable_data_refresh     = bool
    refresh_schedule        = string
    source_environment      = string
  })
  default = {
    enable_data_masking   = true
    enable_synthetic_data = true
    data_retention_days   = 30
    enable_data_refresh   = true
    refresh_schedule      = "0 6 * * 1"  # Monday 6 AM
    source_environment    = "development"
  }
}

variable "enable_test_user_provisioning" {
  description = "Enable automated test user provisioning"
  type        = bool
  default     = true
}

variable "test_user_config" {
  description = "Configuration for test user provisioning"
  type = object({
    user_count          = number
    user_types          = list(string)
    enable_auto_cleanup = bool
    cleanup_schedule    = string
  })
  default = {
    user_count          = 50
    user_types          = ["shipper", "carrier", "admin", "viewer"]
    enable_auto_cleanup = true
    cleanup_schedule    = "0 0 * * 0"  # Sunday midnight
  }
}

# Performance monitoring
variable "enable_apm_integration" {
  description = "Enable Application Performance Monitoring integration"
  type        = bool
  default     = true
}

variable "apm_config" {
  description = "Configuration for APM integration"
  type = object({
    service_name         = string
    sampling_rate        = number
    enable_profiling     = bool
    enable_trace_analysis = bool
    retention_days       = number
  })
  default = {
    service_name         = "cargolynx-tms-staging"
    sampling_rate        = 0.1  # 10% sampling for cost optimization
    enable_profiling     = true
    enable_trace_analysis = true
    retention_days       = 30
  }
}

# Cost optimization
variable "enable_cost_optimization" {
  description = "Enable cost optimization features for staging"
  type        = bool
  default     = true
}

variable "cost_optimization_config" {
  description = "Configuration for cost optimization"
  type = object({
    enable_auto_shutdown           = bool
    shutdown_schedule             = string
    startup_schedule              = string
    enable_preemptible_nodes      = bool
    enable_spot_instances         = bool
    enable_committed_use_discounts = bool
    cost_alert_threshold          = number
  })
  default = {
    enable_auto_shutdown           = true
    shutdown_schedule             = "0 22 * * 1-5"  # 10 PM weekdays
    startup_schedule              = "0 7 * * 1-5"   # 7 AM weekdays
    enable_preemptible_nodes      = true
    enable_spot_instances         = true
    enable_committed_use_discounts = false
    cost_alert_threshold          = 200  # $200/month
  }
}

# Backup and disaster recovery
variable "enable_automated_backups" {
  description = "Enable automated backups for staging environment"
  type        = bool
  default     = true
}

variable "backup_config" {
  description = "Configuration for automated backups"
  type = object({
    backup_schedule       = string
    retention_days        = number
    enable_cross_region   = bool
    backup_encryption     = bool
    enable_point_in_time  = bool
  })
  default = {
    backup_schedule     = "0 3 * * *"  # Daily at 3 AM
    retention_days      = 30
    enable_cross_region = false  # Cost optimization
    backup_encryption   = true
    enable_point_in_time = true
  }
}

# Scaling configuration
variable "scaling_config" {
  description = "Auto-scaling configuration for staging environment"
  type = object({
    enable_cluster_autoscaling    = bool
    enable_horizontal_pod_scaling = bool
    enable_vertical_pod_scaling   = bool
    max_surge                     = string
    max_unavailable              = string
    scale_down_delay             = string
    scale_up_delay               = string
  })
  default = {
    enable_cluster_autoscaling    = true
    enable_horizontal_pod_scaling = true
    enable_vertical_pod_scaling   = false  # Can be resource intensive
    max_surge                     = "25%"
    max_unavailable              = "25%"
    scale_down_delay             = "10m"
    scale_up_delay               = "3m"
  }
}

# Environment lifecycle
variable "environment_lifecycle" {
  description = "Lifecycle configuration for staging environment"
  type = object({
    enable_scheduled_recreation = bool
    recreation_schedule         = string
    enable_drift_detection      = bool
    drift_check_schedule        = string
    enable_config_validation    = bool
    validation_schedule         = string
  })
  default = {
    enable_scheduled_recreation = false  # Manual recreation for staging
    recreation_schedule         = "0 4 * * 0"  # Sunday 4 AM
    enable_drift_detection      = true
    drift_check_schedule        = "0 1 * * *"  # Daily at 1 AM
    enable_config_validation    = true
    validation_schedule         = "0 0 * * *"  # Daily at midnight
  }
}

# Integration testing
variable "integration_testing_config" {
  description = "Configuration for integration testing"
  type = object({
    enable_api_testing        = bool
    enable_ui_testing         = bool
    enable_database_testing   = bool
    enable_performance_testing = bool
    test_suite_schedule       = string
    test_data_reset_schedule  = string
  })
  default = {
    enable_api_testing        = true
    enable_ui_testing         = true
    enable_database_testing   = true
    enable_performance_testing = true
    test_suite_schedule       = "0 5 * * 1-5"  # Weekdays at 5 AM
    test_data_reset_schedule  = "0 6 * * 1"    # Monday at 6 AM
  }
}

# Resource tagging
variable "additional_labels" {
  description = "Additional labels to apply to staging resources"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for key, value in var.additional_labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) &&
      can(regex("^[a-zA-Z0-9_-]{0,63}$", value))
    ])
    error_message = "Labels must follow GCP naming conventions."
  }
}

# Feature flags
variable "feature_flags" {
  description = "Feature flags for staging environment capabilities"
  type = object({
    enable_canary_deployments     = bool
    enable_blue_green_deployments = bool
    enable_feature_toggles        = bool
    enable_a_b_testing           = bool
    enable_traffic_splitting     = bool
    enable_rollback_automation   = bool
  })
  default = {
    enable_canary_deployments     = true
    enable_blue_green_deployments = true
    enable_feature_toggles        = true
    enable_a_b_testing           = false  # May require additional resources
    enable_traffic_splitting     = true
    enable_rollback_automation   = true
  }
}

# External integrations
variable "external_integrations" {
  description = "Configuration for external service integrations"
  type = object({
    enable_datadog_integration = bool
    enable_newrelic_integration = bool
    enable_sentry_integration  = bool
    enable_pagerduty_integration = bool
    enable_jira_integration    = bool
  })
  default = {
    enable_datadog_integration   = false
    enable_newrelic_integration  = false
    enable_sentry_integration    = true
    enable_pagerduty_integration = false
    enable_jira_integration      = false
  }
}

# DNS and networking
variable "dns_config" {
  description = "DNS configuration for staging environment"
  type = object({
    enable_private_dns = bool
    dns_zone_name     = string
    enable_cdn        = bool
    cdn_config = object({
      cache_mode = string
      cache_ttl  = number
    })
  })
  default = {
    enable_private_dns = true
    dns_zone_name     = "staging-cargolynx-internal"
    enable_cdn        = false  # Cost optimization
    cdn_config = {
      cache_mode = "CACHE_ALL_STATIC"
      cache_ttl  = 3600
    }
  }
}