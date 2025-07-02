# =============================================================================
# CargoLynx TMS - Monitoring Module
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Notification Channels
# =============================================================================

# Email notification channel for alerts
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "${var.project_id}-${var.environment}-email-alerts"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
  
  enabled = var.enable_email_notifications
}

# SMS notification channel for critical alerts (production only)
resource "google_monitoring_notification_channel" "sms_alerts" {
  count = var.environment == "production" ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-sms-alerts"
  type         = "sms"
  
  labels = {
    number = var.alert_phone_number
  }
  
  enabled = var.enable_sms_notifications
}

# Slack notification channel
resource "google_monitoring_notification_channel" "slack_alerts" {
  count = var.slack_webhook_url != "" ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-slack-alerts"
  type         = "slack"
  
  labels = {
    url         = var.slack_webhook_url
    channel     = var.slack_channel
  }
  
  enabled = var.enable_slack_notifications
}

# =============================================================================
# Uptime Checks
# =============================================================================

# Application uptime check
resource "google_monitoring_uptime_check_config" "app_uptime" {
  count = var.enable_uptime_checks ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-app-uptime"
  timeout      = "${var.uptime_check_timeout}s"
  period       = "${var.uptime_check_period}s"
  
  http_check {
    port           = var.app_port
    request_method = "GET"
    path           = var.health_check_path
    
    dynamic "auth_info" {
      for_each = var.uptime_auth_required ? [1] : []
      content {
        username = var.uptime_auth_username
        password = var.uptime_auth_password
      }
    }
  }
  
  monitored_resource {
    type = "gce_instance"
    
    labels = {
      project_id   = var.project_id
      instance_id  = var.gke_cluster_name
      zone         = var.zone
    }
  }
  
  content_matchers {
    content = var.uptime_check_content_matcher
    matcher = "CONTAINS_STRING"
  }
  
  selected_regions = var.uptime_check_regions
}

# Database uptime check (for Cloud SQL proxy)
resource "google_monitoring_uptime_check_config" "database_uptime" {
  count = var.enable_database_monitoring ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-db-uptime"
  timeout      = "10s"
  period       = "300s"
  
  tcp_check {
    port = 5432
  }
  
  monitored_resource {
    type = "cloudsql_database"
    
    labels = {
      project_id  = var.project_id
      database_id = var.database_instance_name
    }
  }
  
  selected_regions = ["us-central1"]
}

# =============================================================================
# Alert Policies
# =============================================================================

# High CPU Usage Alert
resource "google_monitoring_alert_policy" "high_cpu_usage" {
  display_name = "${var.project_id}-${var.environment}-high-cpu-usage"
  combiner     = "OR"
  enabled      = var.enable_cpu_alerts
  
  documentation {
    content   = "GKE nodes are experiencing high CPU usage"
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "CPU Usage > ${var.cpu_threshold_percent}%"
    
    condition_threshold {
      filter          = "resource.type=\"gke_node\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\""
      duration        = "${var.alert_duration}s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cpu_threshold_percent / 100
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]
}

# High Memory Usage Alert
resource "google_monitoring_alert_policy" "high_memory_usage" {
  display_name = "${var.project_id}-${var.environment}-high-memory-usage"
  combiner     = "OR"
  enabled      = var.enable_memory_alerts
  
  documentation {
    content   = "GKE nodes are experiencing high memory usage"
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Memory Usage > ${var.memory_threshold_percent}%"
    
    condition_threshold {
      filter          = "resource.type=\"gke_node\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\""
      duration        = "${var.alert_duration}s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.memory_threshold_percent / 100
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]
}

# Database Connection Alert
resource "google_monitoring_alert_policy" "database_connections" {
  count = var.enable_database_monitoring ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-database-connections"
  combiner     = "OR"
  enabled      = true
  
  documentation {
    content   = "Database connection count is approaching limits"
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Database Connections > ${var.db_connection_threshold}"
    
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.database_instance_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.db_connection_threshold
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]
}

# Application Error Rate Alert
resource "google_monitoring_alert_policy" "app_error_rate" {
  count = var.enable_error_rate_alerts ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-app-error-rate"
  combiner     = "OR"
  enabled      = true
  
  documentation {
    content   = "Application error rate is elevated"
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Error Rate > ${var.error_rate_threshold}%"
    
    condition_threshold {
      filter          = "resource.type=\"gke_container\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold / 100
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_alerts.name
  ]
}

# Uptime Check Failure Alert
resource "google_monitoring_alert_policy" "uptime_check_failure" {
  count = var.enable_uptime_checks ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment}-uptime-failure"
  combiner     = "OR"
  enabled      = true
  
  documentation {
    content   = "Application uptime check is failing"
    mime_type = "text/markdown"
  }
  
  conditions {
    display_name = "Uptime Check Failure"
    
    condition_threshold {
      filter          = "resource.type=\"uptime_url\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }
  
  notification_channels = concat(
    [google_monitoring_notification_channel.email_alerts.name],
    var.environment == "production" ? google_monitoring_notification_channel.sms_alerts[*].name : [],
    var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack_alerts[*].name : []
  )
}

# =============================================================================
# Custom Dashboards
# =============================================================================

# Main application dashboard
resource "google_monitoring_dashboard" "main_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.project_id}-${var.environment}-overview"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Node CPU Usage"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gke_node\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\""
                      aggregation = {
                        alignmentPeriod  = "300s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              yAxis = {
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Node Memory Usage"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"gke_node\" AND resource.labels.cluster_name=\"${var.gke_cluster_name}\""
                      aggregation = {
                        alignmentPeriod  = "300s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              yAxis = {
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 12
          height = 4
          widget = {
            title = "Database Connections"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.database_instance_name}\""
                      aggregation = {
                        alignmentPeriod  = "300s"
                        perSeriesAligner = "ALIGN_MEAN"
                      }
                    }
                  }
                  plotType = "LINE"
                }
              ]
              yAxis = {
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

# =============================================================================
# Log-based Metrics
# =============================================================================

# Application error log metric
resource "google_logging_metric" "app_error_metric" {
  count = var.enable_log_metrics ? 1 : 0
  
  name   = "${var.project_id}_${var.environment}_app_errors"
  filter = "resource.type=\"gke_container\" AND severity>=ERROR"
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "1"
    
    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Type of error"
    }
  }
  
  label_extractors = {
    error_type = "EXTRACT(jsonPayload.error_type)"
  }
}

# Database slow query metric
resource "google_logging_metric" "db_slow_query_metric" {
  count = var.enable_database_monitoring ? 1 : 0
  
  name   = "${var.project_id}_${var.environment}_slow_queries"
  filter = "resource.type=\"cloudsql_database\" AND jsonPayload.duration > ${var.slow_query_threshold}"
  
  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "s"
    
    labels {
      key         = "query_type"
      value_type  = "STRING"
      description = "Type of slow query"
    }
  }
  
  label_extractors = {
    query_type = "EXTRACT(jsonPayload.query_type)"
  }
}