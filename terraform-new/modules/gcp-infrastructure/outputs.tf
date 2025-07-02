# =============================================================================
# CargoLynx TMS - GCP Infrastructure Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Network Outputs
# =============================================================================

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = module.networking.vpc_network_id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.networking.vpc_network_name
}

output "gke_subnet_id" {
  description = "The ID of the GKE subnet"
  value       = module.networking.gke_subnet_id
}

output "gke_subnet_name" {
  description = "The name of the GKE subnet"
  value       = module.networking.gke_subnet_name
}

output "database_subnet_id" {
  description = "The ID of the database subnet"
  value       = module.networking.database_subnet_id
}

output "nat_gateway_ip" {
  description = "The external IP address of the NAT gateway"
  value       = module.networking.nat_gateway_ip
}

# =============================================================================
# Security Outputs
# =============================================================================

output "gke_service_account_email" {
  description = "Email address of the GKE service account"
  value       = module.security.gke_service_account_email
}

output "terraform_service_account_email" {
  description = "Email address of the Terraform service account"
  value       = module.security.terraform_service_account_email
}

output "kms_key_ring_id" {
  description = "The ID of the KMS key ring"
  value       = module.security.kms_key_ring_id
}

output "terraform_state_key_id" {
  description = "The ID of the Terraform state encryption key"
  value       = module.security.terraform_state_key_id
}

output "application_data_key_id" {
  description = "The ID of the application data encryption key"
  value       = module.security.application_data_key_id
}

# =============================================================================
# GKE Outputs
# =============================================================================

output "gke_cluster_id" {
  description = "The ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "gke_node_pool_name" {
  description = "The name of the GKE node pool"
  value       = module.gke.node_pool_name
}

# =============================================================================
# Database Outputs
# =============================================================================

output "database_instance_id" {
  description = "The ID of the Cloud SQL instance"
  value       = module.database.instance_id
}

output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.database.instance_name
}

output "database_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = module.database.connection_name
}

output "database_private_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = module.database.private_ip_address
  sensitive   = true
}

output "database_public_ip" {
  description = "The public IP address of the Cloud SQL instance"
  value       = module.database.public_ip_address
  sensitive   = true
}

output "database_name" {
  description = "The name of the default database"
  value       = module.database.database_name
}

output "database_user" {
  description = "The database user name"
  value       = module.database.database_user
}

# =============================================================================
# Storage Outputs
# =============================================================================

output "app_storage_bucket_name" {
  description = "The name of the application storage bucket"
  value       = module.storage.app_storage_bucket_name
}

output "app_storage_bucket_url" {
  description = "The URL of the application storage bucket"
  value       = module.storage.app_storage_bucket_url
}

output "backup_storage_bucket_name" {
  description = "The name of the backup storage bucket"
  value       = module.storage.backup_storage_bucket_name
}

output "backup_storage_bucket_url" {
  description = "The URL of the backup storage bucket"
  value       = module.storage.backup_storage_bucket_url
}

output "logs_storage_bucket_name" {
  description = "The name of the logs storage bucket"
  value       = module.storage.logs_storage_bucket_name
}

output "logs_storage_bucket_url" {
  description = "The URL of the logs storage bucket"
  value       = module.storage.logs_storage_bucket_url
}

# =============================================================================
# Monitoring Outputs
# =============================================================================

output "monitoring_summary" {
  description = "Summary of monitoring configuration"
  value       = module.monitoring.monitoring_summary
}

output "monitoring_urls" {
  description = "URLs for monitoring and operations"
  value       = module.monitoring.monitoring_urls
}

output "storage_summary" {
  description = "Summary of storage configuration"
  value = {
    buckets = {
      app_storage = {
        name = module.storage.app_storage_bucket_name
        url  = module.storage.app_storage_bucket_url
      }
      backup_storage = {
        name = module.storage.backup_storage_bucket_name
        url  = module.storage.backup_storage_bucket_url
      }
      logs_storage = {
        name = module.storage.logs_storage_bucket_name
        url  = module.storage.logs_storage_bucket_url
      }
    }
  }
}

# =============================================================================
# Environment Information
# =============================================================================

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "cost_center" {
  description = "The cost center for billing"
  value       = var.cost_center
}

# =============================================================================
# Infrastructure Summary
# =============================================================================

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure components"
  value = {
    environment           = var.environment
    project_id           = var.project_id
    region               = var.region
    gke_cluster_name     = module.gke.cluster_name
    gke_node_pool_name   = module.gke.node_pool_name
    database_instance    = module.database.instance_name
    vpc_network_name     = module.networking.vpc_network_name
    storage_buckets = {
      app_storage    = module.storage.app_storage_bucket_name
      backup_storage = module.storage.backup_storage_bucket_name
      logs_storage   = module.storage.logs_storage_bucket_name
    }
    service_accounts = {
      gke_sa       = module.security.gke_service_account_email
      terraform_sa = module.security.terraform_service_account_email
    }
  }
}