# =============================================================================
# CargoLynx TMS - Monitoring Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Notification Channel Outputs
# =============================================================================

output "email_notification_channel_name" {
  description = "The name of the email notification channel"
  value       = google_monitoring_notification_channel.email_alerts.name
}

output "email_notification_channel_id" {
  description = "The ID of the email notification channel"
  value       = google_monitoring_notification_channel.email_alerts.id
}

output "sms_notification_channel_name" {
  description = "The name of the SMS notification channel (production only)"
  value       = var.environment == "production" ? google_monitoring_notification_channel.sms_alerts[0].name : null
}

output "slack_notification_channel_name" {
  description = "The name of the Slack notification channel"
  value       = var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack_alerts[0].name : null
}

# =============================================================================
# Uptime Check Outputs
# =============================================================================

output "app_uptime_check_id" {
  description = "The ID of the application uptime check"
  value       = var.enable_uptime_checks ? google_monitoring_uptime_check_config.app_uptime[0].uptime_check_id : null
}

output "app_uptime_check_name" {
  description = "The name of the application uptime check"
  value       = var.enable_uptime_checks ? google_monitoring_uptime_check_config.app_uptime[0].name : null
}

output "database_uptime_check_id" {
  description = "The ID of the database uptime check"
  value       = var.enable_database_monitoring ? google_monitoring_uptime_check_config.database_uptime[0].uptime_check_id : null
}

# =============================================================================
# Alert Policy Outputs
# =============================================================================

output "alert_policy_names" {
  description = "Names of all alert policies"
  value = {
    high_cpu_usage      = google_monitoring_alert_policy.high_cpu_usage.name
    high_memory_usage   = google_monitoring_alert_policy.high_memory_usage.name
    database_connections = var.enable_database_monitoring ? google_monitoring_alert_policy.database_connections[0].name : null
    app_error_rate      = var.enable_error_rate_alerts ? google_monitoring_alert_policy.app_error_rate[0].name : null
    uptime_check_failure = var.enable_uptime_checks ? google_monitoring_alert_policy.uptime_check_failure[0].name : null
  }
}

output "alert_policy_ids" {
  description = "IDs of all alert policies"
  value = {
    high_cpu_usage      = google_monitoring_alert_policy.high_cpu_usage.id
    high_memory_usage   = google_monitoring_alert_policy.high_memory_usage.id
    database_connections = var.enable_database_monitoring ? google_monitoring_alert_policy.database_connections[0].id : null
    app_error_rate      = var.enable_error_rate_alerts ? google_monitoring_alert_policy.app_error_rate[0].id : null
    uptime_check_failure = var.enable_uptime_checks ? google_monitoring_alert_policy.uptime_check_failure[0].id : null
  }
}

# =============================================================================
# Dashboard Outputs
# =============================================================================

output "main_dashboard_id" {
  description = "The ID of the main monitoring dashboard"
  value       = google_monitoring_dashboard.main_dashboard.id
}

output "main_dashboard_url" {
  description = "The URL of the main monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${replace(google_monitoring_dashboard.main_dashboard.id, "projects/${var.project_id}/dashboards/", "")}"
}

# =============================================================================
# Log Metrics Outputs
# =============================================================================

output "log_metrics" {
  description = "Information about log-based metrics"
  value = {
    app_error_metric = var.enable_log_metrics ? {
      id   = google_logging_metric.app_error_metric[0].id
      name = google_logging_metric.app_error_metric[0].name
    } : null
    db_slow_query_metric = var.enable_database_monitoring ? {
      id   = google_logging_metric.db_slow_query_metric[0].id
      name = google_logging_metric.db_slow_query_metric[0].name
    } : null
  }
}

# =============================================================================
# Monitoring Configuration Summary
# =============================================================================

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value = {
    environment = var.environment
    region      = var.region
    
    notification_channels = {
      email_enabled = var.enable_email_notifications
      sms_enabled   = var.enable_sms_notifications && var.environment == "production"
      slack_enabled = var.enable_slack_notifications && var.slack_webhook_url != ""
      alert_email   = var.alert_email
      slack_channel = var.slack_channel
    }
    
    uptime_monitoring = {
      enabled                = var.enable_uptime_checks
      app_port              = var.app_port
      health_check_path     = var.health_check_path
      check_timeout         = var.uptime_check_timeout
      check_period          = var.uptime_check_period
      monitored_regions     = var.uptime_check_regions
      database_monitoring   = var.enable_database_monitoring
    }
    
    alert_thresholds = {
      cpu_threshold_percent    = var.cpu_threshold_percent
      memory_threshold_percent = var.memory_threshold_percent
      db_connection_threshold  = var.db_connection_threshold
      error_rate_threshold     = var.error_rate_threshold
      alert_duration          = var.alert_duration
    }
    
    features = {
      cpu_alerts           = var.enable_cpu_alerts
      memory_alerts        = var.enable_memory_alerts
      database_monitoring  = var.enable_database_monitoring
      error_rate_alerts    = var.enable_error_rate_alerts
      log_metrics         = var.enable_log_metrics
      custom_dashboards    = var.enable_custom_dashboards
      detailed_monitoring  = var.enable_detailed_monitoring
    }
    
    configuration = {
      monitoring_tier     = var.monitoring_tier
      retention_days      = var.retention_days
      sample_rate        = var.sample_rate
      dashboard_time_range = var.dashboard_time_range
      slow_query_threshold = var.slow_query_threshold
    }
    
    infrastructure_targets = {
      gke_cluster_name        = var.gke_cluster_name
      database_instance_name  = var.database_instance_name
      zone                   = var.zone
    }
  }
}

# =============================================================================
# Alert Configuration for External Systems
# =============================================================================

output "alert_configuration" {
  description = "Alert configuration for external integrations"
  value = {
    notification_channels = {
      email = {
        name    = google_monitoring_notification_channel.email_alerts.name
        type    = "email"
        enabled = var.enable_email_notifications
      }
      sms = var.environment == "production" ? {
        name    = google_monitoring_notification_channel.sms_alerts[0].name
        type    = "sms"
        enabled = var.enable_sms_notifications
      } : null
      slack = var.slack_webhook_url != "" ? {
        name    = google_monitoring_notification_channel.slack_alerts[0].name
        type    = "slack"
        enabled = var.enable_slack_notifications
      } : null
    }
    
    critical_alerts = [
      google_monitoring_alert_policy.high_cpu_usage.name,
      google_monitoring_alert_policy.high_memory_usage.name,
      var.enable_uptime_checks ? google_monitoring_alert_policy.uptime_check_failure[0].name : null
    ]
    
    warning_alerts = [
      var.enable_database_monitoring ? google_monitoring_alert_policy.database_connections[0].name : null,
      var.enable_error_rate_alerts ? google_monitoring_alert_policy.app_error_rate[0].name : null
    ]
  }
}

# =============================================================================
# Monitoring URLs for Operations
# =============================================================================

output "monitoring_urls" {
  description = "URLs for monitoring and operations"
  value = {
    main_dashboard = "https://console.cloud.google.com/monitoring/dashboards/custom/${replace(google_monitoring_dashboard.main_dashboard.id, "projects/${var.project_id}/dashboards/", "")}"
    alerting       = "https://console.cloud.google.com/monitoring/alerting"
    uptime_checks  = "https://console.cloud.google.com/monitoring/uptime"
    logs_explorer  = "https://console.cloud.google.com/logs/query"
    metrics_explorer = "https://console.cloud.google.com/monitoring/metrics-explorer"
  }
}