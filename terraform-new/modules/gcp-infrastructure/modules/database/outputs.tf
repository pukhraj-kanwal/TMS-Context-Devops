# =============================================================================
# CargoLynx TMS - Database Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Instance Outputs
# =============================================================================

output "instance_id" {
  description = "The ID of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.id
}

output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "self_link" {
  description = "The self-link of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.self_link
}

output "server_ca_cert" {
  description = "The CA certificate information used to connect to the SQL instance via SSL"
  value       = google_sql_database_instance.postgres.server_ca_cert
  sensitive   = true
}

# =============================================================================
# IP Address Outputs
# =============================================================================

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
  sensitive   = true
}

output "public_ip_address" {
  description = "The public IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.public_ip_address
  sensitive   = true
}

output "first_ip_address" {
  description = "The first IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.first_ip_address
  sensitive   = true
}

# =============================================================================
# Database Outputs
# =============================================================================

output "database_name" {
  description = "The name of the default database"
  value       = google_sql_database.database.name
}

output "database_charset" {
  description = "The charset of the database"
  value       = google_sql_database.database.charset
}

output "database_collation" {
  description = "The collation of the database"
  value       = google_sql_database.database.collation
}

# =============================================================================
# User Outputs
# =============================================================================

output "database_user" {
  description = "The name of the main database user"
  value       = google_sql_user.app_user.name
}

output "readonly_user" {
  description = "The name of the read-only database user"
  value       = google_sql_user.readonly_user.name
}

# =============================================================================
# SSL Certificate Outputs
# =============================================================================

output "client_cert" {
  description = "The client certificate for SSL connection"
  value       = google_sql_ssl_cert.client_cert.cert
  sensitive   = true
}

output "client_key" {
  description = "The client private key for SSL connection"
  value       = google_sql_ssl_cert.client_cert.private_key
  sensitive   = true
}

output "client_cert_common_name" {
  description = "The common name of the client certificate"
  value       = google_sql_ssl_cert.client_cert.common_name
}

# =============================================================================
# Connection Information
# =============================================================================

output "database_url" {
  description = "Database connection URL (without password)"
  value       = "postgresql://${google_sql_user.app_user.name}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.database.name}?sslmode=require"
  sensitive   = true
}

output "readonly_database_url" {
  description = "Read-only database connection URL (without password)"
  value       = "postgresql://${google_sql_user.readonly_user.name}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.database.name}?sslmode=require"
  sensitive   = true
}

# =============================================================================
# Database Summary
# =============================================================================

output "database_summary" {
  description = "Summary of database configuration"
  value = {
    environment         = var.environment
    instance_name      = google_sql_database_instance.postgres.name
    database_version   = var.database_version
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_size         = var.database_disk_size
    max_disk_size     = var.database_max_disk_size
    database_name     = google_sql_database.database.name
    users = {
      app_user      = google_sql_user.app_user.name
      readonly_user = google_sql_user.readonly_user.name
    }
    features = {
      backup_enabled           = true
      point_in_time_recovery  = true
      ssl_required            = true
      private_networking      = true
      deletion_protection     = var.database_deletion_protection
    }
    connection = {
      private_ip  = google_sql_database_instance.postgres.private_ip_address
      public_ip   = google_sql_database_instance.postgres.public_ip_address
    }
  }
  sensitive = true
}