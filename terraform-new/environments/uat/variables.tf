# CargoLynx TMS - UAT Environment Variables
# User Acceptance Testing environment for business validation

# Basic project configuration
variable "project_id" {
  description = "GCP project ID for UAT environment"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with letter, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "GCP region for UAT resources"
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
variable "uat_domain" {
  description = "Domain name for UAT environment"
  type        = string
  default     = "uat.cargolynx.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.uat_domain))
    error_message = "Domain must be a valid domain name format."
  }
}

# Notification configuration
variable "notification_channels" {
  description = "List of notification channel configurations for UAT alerts"
  type = list(object({
    type        = string
    destination = string
    enabled     = bool
  }))
  default = [
    {
      type        = "email"
      destination = "uat-alerts@cargolynx.com"
      enabled     = true
    },
    {
      type        = "slack"
      destination = "#uat-alerts"
      enabled     = true
    },
    {
      type        = "webhook"
      destination = "https://hooks.cargolynx.com/uat-alerts"
      enabled     = false
    }
  ]
}

variable "alert_email" {
  description = "Primary email for UAT environment alerts"
  type        = string
  default     = "uat-alerts@cargolynx.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for UAT notifications (should be stored in secret manager)"
  type        = string
  default     = ""
  sensitive   = true
}

# Business and product team configuration
variable "business_team_members" {
  description = "List of business team members with UAT access"
  type = list(object({
    email = string
    role  = string
    department = string
  }))
  default = [
    {
      email = "product@cargolynx.com"
      role  = "roles/editor"
      department = "product"
    },
    {
      email = "business-analysts@cargolynx.com"
      role  = "roles/viewer"
      department = "business"
    },
    {
      email = "qa-lead@cargolynx.com"
      role  = "roles/editor"
      department = "quality-assurance"
    }
  ]
}

variable "external_stakeholders" {
  description = "External stakeholders with UAT access"
  type = list(object({
    email = string
    role  = string
    organization = string
    access_duration_days = number
  }))
  default = []
}

# User testing configuration
variable "enable_session_recording" {
  description = "Enable user session recording for UAT"
  type        = bool
  default     = true
}

variable "session_recording_config" {
  description = "Configuration for session recording"
  type = object({
    record_mouse_movements = bool
    record_clicks         = bool
    record_keystrokes     = bool
    record_scroll         = bool
    blur_sensitive_data   = bool
    retention_days        = number
  })
  default = {
    record_mouse_movements = true
    record_clicks         = true
    record_keystrokes     = false  # Privacy consideration
    record_scroll         = true
    blur_sensitive_data   = true
    retention_days        = 30
  }
}

variable "enable_user_analytics" {
  description = "Enable detailed user analytics tracking"
  type        = bool
  default     = true
}

variable "user_analytics_config" {
  description = "Configuration for user analytics"
  type = object({
    track_page_views      = bool
    track_user_flows      = bool
    track_conversion_events = bool
    track_error_events    = bool
    enable_heatmaps       = bool
    enable_funnel_analysis = bool
    anonymize_user_data   = bool
  })
  default = {
    track_page_views      = true
    track_user_flows      = true
    track_conversion_events = true
    track_error_events    = true
    enable_heatmaps       = true
    enable_funnel_analysis = true
    anonymize_user_data   = true
  }
}

variable "enable_feedback_collection" {
  description = "Enable user feedback collection mechanisms"
  type        = bool
  default     = true
}

variable "feedback_collection_config" {
  description = "Configuration for feedback collection"
  type = object({
    enable_in_app_feedback   = bool
    enable_post_session_survey = bool
    enable_nps_surveys       = bool
    enable_bug_reporting     = bool
    feedback_retention_days  = number
  })
  default = {
    enable_in_app_feedback   = true
    enable_post_session_survey = true
    enable_nps_surveys       = false  # May be too frequent for UAT
    enable_bug_reporting     = true
    feedback_retention_days  = 90
  }
}

# Test data management
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
    data_volume_scale       = string
  })
  default = {
    enable_data_masking   = true
    enable_synthetic_data = true
    data_retention_days   = 60
    enable_data_refresh   = true
    refresh_schedule      = "0 2 * * 1"  # Monday 2 AM
    source_environment    = "staging"
    data_volume_scale     = "medium"
  }
}

variable "test_scenarios" {
  description = "Predefined test scenarios for UAT"
  type = list(object({
    name            = string
    description     = string
    data_requirements = list(string)
    user_roles      = list(string)
    estimated_duration_hours = number
  }))
  default = [
    {
      name            = "End-to-End Shipment Flow"
      description     = "Complete shipment lifecycle from creation to delivery"
      data_requirements = ["shippers", "carriers", "shipments", "tracking_events"]
      user_roles      = ["shipper", "carrier", "admin"]
      estimated_duration_hours = 4
    },
    {
      name            = "Multi-Modal Transportation"
      description     = "Shipments using multiple transportation modes"
      data_requirements = ["multi_modal_routes", "carrier_networks", "transfer_points"]
      user_roles      = ["shipper", "carrier", "logistics_coordinator"]
      estimated_duration_hours = 6
    },
    {
      name            = "Real-Time Tracking Validation"
      description     = "Validate real-time tracking and notifications"
      data_requirements = ["active_shipments", "gps_data", "notification_templates"]
      user_roles      = ["shipper", "customer", "dispatcher"]
      estimated_duration_hours = 3
    }
  ]
}

# Load testing configuration
variable "enable_load_testing" {
  description = "Enable load testing resources for UAT"
  type        = bool
  default     = true
}

variable "load_testing_config" {
  description = "Configuration for load testing in UAT"
  type = object({
    max_concurrent_users = number
    test_duration_minutes = number
    ramp_up_time_minutes = number
    target_endpoints = list(string)
    test_scenarios = list(string)
    enable_stress_testing = bool
  })
  default = {
    max_concurrent_users = 25   # Moderate load for UAT
    test_duration_minutes = 30
    ramp_up_time_minutes = 10
    target_endpoints = [
      "/api/health",
      "/api/shipments",
      "/api/tracking",
      "/api/carriers",
      "/auth/login"
    ]
    test_scenarios = ["normal_usage", "peak_usage"]
    enable_stress_testing = false
  }
}

# Synthetic monitoring
variable "enable_synthetic_monitoring" {
  description = "Enable synthetic monitoring for UAT"
  type        = bool
  default     = true
}

variable "synthetic_monitoring_config" {
  description = "Configuration for synthetic monitoring"
  type = object({
    check_frequency_minutes = number
    timeout_seconds        = number
    regions               = list(string)
    enable_ssl_checks     = bool
    enable_api_checks     = bool
    enable_ui_checks      = bool
  })
  default = {
    check_frequency_minutes = 5
    timeout_seconds        = 30
    regions               = ["us-central1", "us-east1"]
    enable_ssl_checks     = true
    enable_api_checks     = true
    enable_ui_checks      = true
  }
}

# CI/CD integration
variable "enable_cicd_integration" {
  description = "Enable CI/CD integration for UAT deployments"
  type        = bool
  default     = true
}

variable "cicd_service_account" {
  description = "Service account email for CI/CD pipeline integration"
  type        = string
  default     = ""
  validation {
    condition = var.cicd_service_account == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.iam\\.gserviceaccount\\.com$", var.cicd_service_account))
    error_message = "CI/CD service account must be empty or a valid GCP service account email."
  }
}

variable "cicd_config" {
  description = "CI/CD configuration for UAT"
  type = object({
    enable_auto_deployment    = bool
    deployment_branches      = list(string)
    require_approval        = bool
    approval_timeout_hours  = number
    enable_rollback_automation = bool
    health_check_timeout_minutes = number
  })
  default = {
    enable_auto_deployment    = false  # Manual approval for UAT
    deployment_branches      = ["release/*", "uat"]
    require_approval        = true
    approval_timeout_hours  = 24
    enable_rollback_automation = true
    health_check_timeout_minutes = 15
  }
}

# Security and compliance
variable "enable_compliance_monitoring" {
  description = "Enable compliance monitoring for UAT"
  type        = bool
  default     = true
}

variable "compliance_config" {
  description = "Compliance monitoring configuration"
  type = object({
    frameworks          = list(string)
    scan_schedule       = string
    enable_audit_logging = bool
    retention_days      = number
  })
  default = {
    frameworks          = ["SOC2", "GDPR"]
    scan_schedule       = "0 3 * * *"  # Daily at 3 AM
    enable_audit_logging = true
    retention_days      = 90
  }
}

variable "security_config" {
  description = "Security configuration for UAT environment"
  type = object({
    enable_vulnerability_scanning = bool
    scan_schedule                = string
    enable_penetration_testing   = bool
    enable_security_monitoring   = bool
    enable_access_reviews        = bool
    access_review_frequency_days = number
  })
  default = {
    enable_vulnerability_scanning = true
    scan_schedule                = "0 4 * * *"  # Daily at 4 AM
    enable_penetration_testing   = false
    enable_security_monitoring   = true
    enable_access_reviews        = true
    access_review_frequency_days = 30
  }
}

# Performance monitoring
variable "performance_monitoring_config" {
  description = "Performance monitoring configuration for UAT"
  type = object({
    enable_apm              = bool
    enable_real_user_monitoring = bool
    enable_performance_budgets = bool
    enable_core_web_vitals  = bool
    sampling_rate          = number
    retention_days         = number
  })
  default = {
    enable_apm              = true
    enable_real_user_monitoring = true
    enable_performance_budgets = true
    enable_core_web_vitals  = true
    sampling_rate          = 0.5  # 50% sampling for detailed UAT analysis
    retention_days         = 60
  }
}

variable "performance_sla_targets" {
  description = "Performance SLA targets for UAT environment"
  type = object({
    availability_percentage = number
    response_time_ms       = number
    error_rate_percentage  = number
    throughput_requests_per_minute = number
  })
  default = {
    availability_percentage = 99.0   # Relaxed for UAT
    response_time_ms       = 2000   # 2 seconds
    error_rate_percentage  = 1.0    # 1%
    throughput_requests_per_minute = 1000
  }
}

# Business validation configuration
variable "business_validation_config" {
  description = "Configuration for business validation workflows"
  type = object({
    enable_workflow_tracking    = bool
    enable_business_metrics     = bool
    enable_kpi_monitoring      = bool
    enable_roi_calculations    = bool
    validation_period_days     = number
  })
  default = {
    enable_workflow_tracking    = true
    enable_business_metrics     = true
    enable_kpi_monitoring      = true
    enable_roi_calculations    = false
    validation_period_days     = 14
  }
}

variable "business_kpis" {
  description = "Key Performance Indicators to track during UAT"
  type = list(object({
    name        = string
    description = string
    target_value = number
    unit        = string
    frequency   = string
  }))
  default = [
    {
      name        = "shipment_creation_time"
      description = "Average time to create a shipment"
      target_value = 3
      unit        = "minutes"
      frequency   = "daily"
    },
    {
      name        = "user_task_completion_rate"
      description = "Percentage of users completing key tasks"
      target_value = 90
      unit        = "percentage"
      frequency   = "daily"
    },
    {
      name        = "system_usability_score"
      description = "Average user experience score"
      target_value = 4.0
      unit        = "score_out_of_5"
      frequency   = "weekly"
    }
  ]
}

# Integration testing
variable "integration_testing_config" {
  description = "Configuration for integration testing in UAT"
  type = object({
    enable_external_api_testing = bool
    enable_payment_testing      = bool
    enable_notification_testing = bool
    enable_reporting_testing    = bool
    test_schedule              = string
  })
  default = {
    enable_external_api_testing = true
    enable_payment_testing      = true
    enable_notification_testing = true
    enable_reporting_testing    = true
    test_schedule              = "0 6 * * 1-5"  # Weekdays at 6 AM
  }
}

variable "external_service_endpoints" {
  description = "External service endpoints for UAT testing"
  type = map(object({
    url          = string
    api_key_secret = string
    enable_testing = bool
    test_mode     = bool
  }))
  default = {
    stripe = {
      url          = "https://api.stripe.com/v1"
      api_key_secret = "stripe-test-api-key"
      enable_testing = true
      test_mode     = true
    }
    twilio = {
      url          = "https://api.twilio.com/2010-04-01"
      api_key_secret = "twilio-test-api-key"
      enable_testing = true
      test_mode     = true
    }
    sendgrid = {
      url          = "https://api.sendgrid.com/v3"
      api_key_secret = "sendgrid-test-api-key"
      enable_testing = true
      test_mode     = true
    }
  }
}

# Backup and recovery
variable "backup_config" {
  description = "Backup configuration for UAT environment"
  type = object({
    enable_automated_backups = bool
    backup_schedule         = string
    retention_days          = number
    enable_point_in_time_recovery = bool
    enable_cross_region_backup = bool
  })
  default = {
    enable_automated_backups = true
    backup_schedule         = "0 5 * * *"  # Daily at 5 AM
    retention_days          = 60
    enable_point_in_time_recovery = true
    enable_cross_region_backup = false
  }
}

# Resource optimization
variable "resource_optimization_config" {
  description = "Resource optimization settings for UAT"
  type = object({
    enable_auto_scaling     = bool
    enable_cost_optimization = bool
    enable_resource_monitoring = bool
    cost_alert_threshold    = number
    scaling_policy         = string
  })
  default = {
    enable_auto_scaling     = true
    enable_cost_optimization = true
    enable_resource_monitoring = true
    cost_alert_threshold    = 300  # $300/month
    scaling_policy         = "conservative"
  }
}

# Documentation and reporting
variable "documentation_config" {
  description = "Documentation and reporting configuration"
  type = object({
    enable_automated_reporting = bool
    report_schedule           = string
    report_recipients         = list(string)
    enable_test_documentation = bool
    enable_issue_tracking     = bool
  })
  default = {
    enable_automated_reporting = true
    report_schedule           = "0 17 * * 5"  # Friday 5 PM
    report_recipients         = ["uat-team@cargolynx.com"]
    enable_test_documentation = true
    enable_issue_tracking     = true
  }
}

# Environment lifecycle
variable "environment_lifecycle_config" {
  description = "Environment lifecycle management configuration"
  type = object({
    enable_health_checks         = bool
    health_check_frequency_minutes = number
    enable_auto_recovery        = bool
    enable_maintenance_windows  = bool
    maintenance_schedule        = string
  })
  default = {
    enable_health_checks         = true
    health_check_frequency_minutes = 5
    enable_auto_recovery        = true
    enable_maintenance_windows  = true
    maintenance_schedule        = "0 6 * * 6"  # Saturday 6 AM
  }
}

# Resource tagging
variable "additional_labels" {
  description = "Additional labels to apply to UAT resources"
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

# Feature enablement
variable "feature_flags" {
  description = "Feature flags for UAT environment capabilities"
  type = object({
    enable_experimental_features = bool
    enable_beta_features        = bool
    enable_preview_features     = bool
    enable_debug_features       = bool
  })
  default = {
    enable_experimental_features = false
    enable_beta_features        = true
    enable_preview_features     = true
    enable_debug_features       = true
  }
}

# Notification preferences
variable "notification_preferences" {
  description = "Notification preferences for UAT environment"
  type = object({
    alert_severity_levels     = list(string)
    notification_frequency   = string
    escalation_enabled       = bool
    escalation_timeout_minutes = number
    quiet_hours_enabled      = bool
    quiet_hours_start        = string
    quiet_hours_end          = string
  })
  default = {
    alert_severity_levels     = ["critical", "high", "medium"]
    notification_frequency   = "immediate"
    escalation_enabled       = true
    escalation_timeout_minutes = 30
    quiet_hours_enabled      = true
    quiet_hours_start        = "22:00"
    quiet_hours_end          = "08:00"
  }
}