# =============================================================================
# CargoLynx TMS - Local Environment Configuration
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
  
  # Local backend for development
  backend "local" {
    path = "terraform.tfstate"
  }
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
# Local Development Environment
# =============================================================================

module "infrastructure" {
  source = "../../modules/gcp-infrastructure"
  
  # Core Configuration
  project_id  = var.project_id
  environment = "local"
  region      = var.region
  cost_center = "development"
  
  # Domain Configuration
  domain_name = var.domain_name
  
  # Network Configuration - Local Development
  gke_subnet_cidr      = "10.0.1.0/24"
  gke_pods_cidr        = "10.1.0.0/16"
  gke_services_cidr    = "10.2.0.0/16"
  database_subnet_cidr = "10.0.2.0/24"
  
  # GKE Configuration - FREE TIER Optimized
  enable_gke_autopilot     = false            # Standard mode for cost control
  gke_node_machine_type    = "e2-micro"       # Always Free tier
  gke_node_disk_size       = 10               # Minimal disk
  gke_node_count           = 1                # Single node
  gke_min_nodes            = 1                # Minimum scaling
  gke_max_nodes            = 3                # Maximum scaling
  preemptible_node_pool    = true             # Cost savings
  spot_node_pool           = false            # Keep simple
  
  # Database Configuration - FREE TIER
  database_version              = "POSTGRES_15"
  database_tier                = "db-f1-micro"    # Always Free
  database_disk_size           = 10               # Minimal size
  database_max_disk_size       = 20               # Small auto-resize limit
  database_availability_type   = "ZONAL"          # Single zone for cost
  database_deletion_protection = false            # Development environment
  database_password           = "dev-password-123" # Development only
  
  # Storage Configuration - Cost Optimized
  enable_bucket_versioning       = false           # Reduce storage costs
  bucket_lifecycle_age_nearline  = 7               # Quick transition
  bucket_lifecycle_age_coldline  = 30              # Aggressive lifecycle
  bucket_lifecycle_age_archive   = 90              # Short archive period
  bucket_lifecycle_age_delete    = 365             # Delete after 1 year
  
  # Monitoring Configuration
  alert_email = var.alert_email
}

# =============================================================================
# Local Development Outputs
# =============================================================================

output "infrastructure" {
  description = "Complete infrastructure configuration for local environment"
  value       = module.infrastructure
  sensitive   = true
}

output "quick_access" {
  description = "Quick access information for local development"
  value = {
    environment           = "local"
    gke_cluster_name     = module.infrastructure.gke_cluster_name
    gke_cluster_endpoint = module.infrastructure.gke_cluster_endpoint
    database_connection  = module.infrastructure.database_connection_name
    storage_bucket       = module.infrastructure.storage_summary.buckets.app_storage.name
    
    # Development URLs
    monitoring_dashboard = module.infrastructure.monitoring_urls.main_dashboard
    logs_explorer       = module.infrastructure.monitoring_urls.logs_explorer
    
    # Connection Commands
    kubectl_config = "gcloud container clusters get-credentials ${module.infrastructure.gke_cluster_name} --zone ${var.zone} --project ${var.project_id}"
    
    # Cost Optimization Status
    cost_tier = "FREE_TIER_OPTIMIZED"
    estimated_monthly_cost = "$0-15"
  }
}