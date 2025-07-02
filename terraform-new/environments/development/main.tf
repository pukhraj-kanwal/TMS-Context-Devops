# =============================================================================
# CargoLynx TMS - Development Environment Configuration
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
  
  # Backend configuration handled via backend config file during deployment
  # For validation testing, local state is used
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# =============================================================================
# Development Environment - Cost-Optimized with Production Features
# =============================================================================

module "infrastructure" {
  source = "../../modules/gcp-infrastructure"
  
  # Core Configuration (Required)
  project_id  = var.project_id
  environment = "development"
  region      = var.region
  
  # Domain Configuration (Required)
  domain_name = var.domain_name
  
  # Network Configuration (Required)
  
  gke_subnet_cidr       = "10.10.1.0/24"
  gke_pods_cidr         = "10.11.0.0/16"
  gke_services_cidr     = "10.12.0.0/16"
  database_subnet_cidr  = "10.10.2.0/24"
  
  # GKE Configuration (Required)
  gke_node_machine_type = "e2-standard-2"
  gke_node_disk_size    = 50
  gke_node_count        = 2
  gke_min_nodes         = 2
  gke_max_nodes         = 8
  preemptible_node_pool = true
  spot_node_pool        = false
  
  # Database Configuration (Required)
  database_tier              = "db-n1-standard-1"
  database_disk_size         = 100
  database_max_disk_size     = 500
  database_version           = "POSTGRES_15"
  database_password          = "dev-password-123"
  database_deletion_protection = false
  database_availability_type = "ZONAL"
  
  # Storage Configuration (Required)
  enable_bucket_versioning       = true
  bucket_lifecycle_age_nearline  = 30
  bucket_lifecycle_age_coldline  = 90
  bucket_lifecycle_age_archive   = 180
  bucket_lifecycle_age_delete    = 730
  
  # Monitoring Configuration (Required)
  alert_email = var.alert_email
  
  # Cost Center Configuration (Required)
  cost_center = "development"
}

# =============================================================================
# Development Environment Helpers
# =============================================================================

# Auto-shutdown schedule for cost optimization
resource "google_cloud_scheduler_job" "auto_shutdown" {
  count = var.enable_auto_shutdown ? 1 : 0
  
  name        = "${var.project_id}-dev-auto-shutdown"
  description = "Auto-shutdown development environment for cost savings"
  schedule    = "0 22 * * 1-5"  # 10 PM weekdays
  time_zone   = "UTC"
  
  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/stop"
    
    headers = {
      "Content-Type"  = "application/json"
      "Authorization" = "Bearer ${data.google_service_account_access_token.scheduler_token.access_token}"
    }
  }
}

# Auto-startup schedule for development hours
resource "google_cloud_scheduler_job" "auto_startup" {
  count = var.enable_auto_shutdown ? 1 : 0
  
  name        = "${var.project_id}-dev-auto-startup"
  description = "Auto-startup development environment for work hours"
  schedule    = "0 8 * * 1-5"   # 8 AM weekdays
  time_zone   = "UTC"
  
  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/start"
    
    headers = {
      "Content-Type"  = "application/json"
      "Authorization" = "Bearer ${data.google_service_account_access_token.scheduler_token.access_token}"
    }
  }
}

# Service account token for scheduler operations
data "google_service_account_access_token" "scheduler_token" {
  target_service_account = module.infrastructure.terraform_service_account_email
  scopes                = ["https://www.googleapis.com/auth/cloud-platform"]
  lifetime              = "1h"
}

# =============================================================================
# Development Outputs
# =============================================================================

output "infrastructure" {
  description = "Complete infrastructure configuration for development environment"
  value       = module.infrastructure
  sensitive   = true
}

output "development_endpoints" {
  description = "Development environment access points"
  value = {
    environment           = "development"
    gke_cluster_name     = module.infrastructure.gke_cluster_name
    gke_cluster_endpoint = module.infrastructure.gke_cluster_endpoint
    database_connection  = module.infrastructure.database_connection_name
    storage_bucket       = module.infrastructure.storage_summary.buckets.app_storage.name
    
    # Development URLs
    monitoring_dashboard = module.infrastructure.monitoring_urls.main_dashboard
    logs_explorer       = module.infrastructure.monitoring_urls.logs_explorer
    metrics_explorer    = module.infrastructure.monitoring_urls.metrics_explorer
    
    # Development Operations
    kubectl_config = "gcloud container clusters get-credentials ${module.infrastructure.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
    
    # Development Status
    cost_optimization = "ENABLED"
    auto_shutdown    = var.enable_auto_shutdown ? "ENABLED" : "DISABLED"
    monitoring_tier  = "STANDARD"
    backup_schedule  = "WEEKLY"
  }
}

output "cost_optimization" {
  description = "Development cost optimization features"
  value = {
    preemptible_nodes    = true
    auto_shutdown       = var.enable_auto_shutdown
    shutdown_schedule   = "22:00 UTC weekdays"
    startup_schedule    = "08:00 UTC weekdays"
    estimated_savings   = "60-70% vs production"
    single_zone         = true
    reduced_monitoring  = true
  }
}

output "development_features" {
  description = "Development-specific features and capabilities"
  value = {
    ssl_certificates    = true
    load_balancing     = true
    auto_scaling       = true
    private_cluster    = true
    workload_identity  = true
    network_policies   = true
    backup_enabled     = true
    logging_enabled    = true
    monitoring_enabled = true
  }
}