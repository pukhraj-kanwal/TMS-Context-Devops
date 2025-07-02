# =============================================================================
# CargoLynx TMS - Database Module
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# =============================================================================
# Cloud SQL Instance
# =============================================================================

resource "google_sql_database_instance" "postgres" {
  name             = "${var.environment}-postgres-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region          = var.region
  project         = var.project_id

  # Deletion protection
  deletion_protection = var.database_deletion_protection

  settings {
    tier                        = var.database_tier
    availability_type          = var.database_availability_type
    disk_size                  = var.database_disk_size
    disk_type                  = "PD_SSD"
    disk_autoresize           = true
    disk_autoresize_limit     = var.database_max_disk_size

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                    = "02:00"
      location                      = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # IP configuration for private networking
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                              = var.vpc_network_id
      enable_private_path_for_google_cloud_services = true
    }

    # Maintenance window
    maintenance_window {
      day         = 7  # Sunday
      hour        = 2  # 2 AM
      update_track = "stable"
    }

    # Database flags for optimization
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_temp_files"
      value = "0"
    }

    database_flags {
      name  = "track_activity_query_size"
      value = "2048"
    }

    # User labels for resource management
    user_labels = {
      environment = var.environment
      managed-by  = "terraform"
      cost-center = var.cost_center
    }
  }

  depends_on = [
    var.apis_enabled,
    var.private_vpc_connection
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# Random ID for unique database instance naming
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# =============================================================================
# Default Database
# =============================================================================

resource "google_sql_database" "database" {
  name       = "${var.environment}_cargolynx_db"
  instance   = google_sql_database_instance.postgres.name
  project    = var.project_id
  charset    = "UTF8"
  collation  = "en_US.UTF8"

  depends_on = [
    google_sql_database_instance.postgres
  ]
}

# =============================================================================
# Database Users
# =============================================================================

# Application user
resource "google_sql_user" "app_user" {
  name     = "${var.environment}_app_user"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
  password = var.database_password

  depends_on = [
    google_sql_database_instance.postgres
  ]
}

# Read-only user for analytics/reporting
resource "google_sql_user" "readonly_user" {
  name     = "${var.environment}_readonly_user"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
  password = var.readonly_database_password

  depends_on = [
    google_sql_database_instance.postgres
  ]
}

# =============================================================================
# SSL Certificate
# =============================================================================

resource "google_sql_ssl_cert" "client_cert" {
  common_name = "${var.environment}-client-cert"
  instance    = google_sql_database_instance.postgres.name
  project     = var.project_id

  depends_on = [
    google_sql_database_instance.postgres
  ]
}