# =============================================================================
# CargoLynx TMS - Infrastructure Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# Project Information
output "project_id" {
  description = "Google Cloud Project ID"
  value       = var.project_id
}

output "region" {
  description = "Google Cloud region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# VPC Network Outputs
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "vpc_network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.main.self_link
}

# Subnet Outputs
output "gke_subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_cidr" {
  description = "CIDR range of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "database_subnet_name" {
  description = "Name of the database subnet"
  value       = google_compute_subnetwork.database_subnet.name
}

output "database_subnet_cidr" {
  description = "CIDR range of the database subnet"
  value       = google_compute_subnetwork.database_subnet.ip_cidr_range
}

# NAT Gateway Outputs
output "nat_gateway_name" {
  description = "Name of the NAT gateway"
  value       = google_compute_router_nat.main.name
}

# GKE Cluster Outputs
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "gke_cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_cluster_version" {
  description = "Version of the GKE cluster"
  value       = google_container_cluster.main.master_version
}

# Node Pool Outputs
output "gke_node_pool_name" {
  description = "Name of the GKE node pool"
  value       = var.enable_gke_autopilot ? null : google_container_node_pool.standard_pool[0].name
}

output "gke_node_pool_instance_group_urls" {
  description = "Instance group URLs of the GKE node pool"
  value       = var.enable_gke_autopilot ? [] : google_container_node_pool.standard_pool[0].instance_group_urls
}

# Database Outputs
output "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "database_instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.main.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Name of the main database"
  value       = google_sql_database.cargolynx_tms.name
}

output "database_user_name" {
  description = "Name of the database user"
  value       = google_sql_user.app_user.name
  sensitive   = true
}

# Service Account Outputs
output "gke_service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_service_account.email
}

output "terraform_service_account_email" {
  description = "Email of the Terraform service account"
  value       = google_service_account.terraform_service_account.email
}

# Storage Outputs
output "terraform_state_bucket" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "app_data_bucket" {
  description = "Name of the application data bucket"
  value       = google_storage_bucket.app_data.name
}

# KMS Outputs
output "kms_key_ring_name" {
  description = "Name of the KMS key ring"
  value       = google_kms_key_ring.main.name
}

output "terraform_state_kms_key_name" {
  description = "Name of the Terraform state KMS key"
  value       = google_kms_crypto_key.terraform_state_key.name
}

output "app_data_kms_key_name" {
  description = "Name of the application data KMS key"
  value       = google_kms_crypto_key.app_data_key.name
}

# Monitoring Outputs
output "monitoring_notification_channel" {
  description = "Name of the monitoring notification channel"
  value       = google_monitoring_notification_channel.email.name
}

output "uptime_check_name" {
  description = "Name of the uptime check"
  value       = google_monitoring_uptime_check_config.api_health.display_name
}

# Connection Information
output "database_connection_string" {
  description = "Database connection string for applications"
  value       = "postgresql://${google_sql_user.app_user.name}:${var.database_password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.cargolynx_tms.name}"
  sensitive   = true
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region=${var.region} --project=${var.project_id}"
}

# Resource Labels
output "common_labels" {
  description = "Common labels applied to all resources"
  value = {
    project      = "cargolynx-tms"
    environment  = var.environment
    managed-by   = "terraform"
    team         = "platform-engineering"
    cost-center  = "engineering"
    component    = "infrastructure"
  }
}

# Network Security
output "firewall_rules" {
  description = "List of firewall rule names"
  value = [
    google_compute_firewall.allow_internal.name,
    google_compute_firewall.allow_health_checks.name,
    google_compute_firewall.allow_https.name,
    google_compute_firewall.deny_all.name
  ]
}

# Infrastructure Status
output "infrastructure_ready" {
  description = "Indicates if the infrastructure is ready for application deployment"
  value = {
    vpc_created     = google_compute_network.main.name != null
    gke_created     = google_container_cluster.main.name != null
    database_ready  = google_sql_database_instance.main.name != null
    storage_ready   = google_storage_bucket.terraform_state.name != null && google_storage_bucket.app_data.name != null
    kms_ready      = google_kms_key_ring.main.name != null
  }
}