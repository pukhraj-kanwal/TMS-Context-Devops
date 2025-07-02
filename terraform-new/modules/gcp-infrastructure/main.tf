# =============================================================================
# CargoLynx TMS - GCP Infrastructure Module
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

# =============================================================================
# Local Values
# =============================================================================

locals {
  name_prefix = "cargolynx-${var.environment}"
  short_prefix = "cargo-${substr(var.environment, 0, 4)}"
  
  common_labels = {
    project      = "cargolynx-tms"
    environment  = var.environment
    managed-by   = "terraform"
    team         = "platform-engineering"
    cost-center  = var.cost_center
    component    = "infrastructure"
  }
}

# =============================================================================
# Networking Module
# =============================================================================

module "networking" {
  source = "./modules/networking"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  
  # Network configuration
  gke_subnet_cidr      = var.gke_subnet_cidr
  gke_pods_cidr        = var.gke_pods_cidr
  gke_services_cidr    = var.gke_services_cidr
  database_subnet_cidr = var.database_subnet_cidr
}

# =============================================================================
# Security Module
# =============================================================================

module "security" {
  source = "./modules/security"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
}

# =============================================================================
# GKE Module
# =============================================================================

module "gke" {
  source = "./modules/gke"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  
  # Network dependencies - Fixed interface mapping
  vpc_network_id                    = module.networking.vpc_network_id
  vpc_network_name                  = module.networking.vpc_network_name
  gke_subnet_id                     = module.networking.gke_subnet_id
  gke_subnet_name                   = module.networking.gke_subnet_name
  gke_pods_secondary_range_name     = module.networking.gke_pods_secondary_range_name
  gke_services_secondary_range_name = module.networking.gke_services_secondary_range_name
  
  # GKE configuration - Fixed variable name
  enable_autopilot        = var.enable_gke_autopilot
  gke_node_machine_type   = var.gke_node_machine_type
  gke_node_disk_size      = var.gke_node_disk_size
  gke_node_count          = var.gke_node_count
  gke_min_nodes          = var.gke_min_nodes
  gke_max_nodes          = var.gke_max_nodes
  preemptible_node_pool  = var.preemptible_node_pool
  spot_node_pool         = var.spot_node_pool
  gke_node_taints        = var.gke_node_taints
  
  # Security dependencies
  gke_service_account_email = module.security.gke_service_account_email
  
  depends_on = [
    module.networking,
    module.security
  ]
}

# =============================================================================
# Database Module
# =============================================================================

module "database" {
  source = "./modules/database"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  
  # Network dependencies - Fixed interface mapping
  vpc_network_id         = module.networking.vpc_network_id
  private_vpc_connection = module.networking.private_vpc_connection_service
  
  # Database configuration
  database_version              = var.database_version
  database_tier                = var.database_tier
  database_disk_size           = var.database_disk_size
  database_max_disk_size       = var.database_max_disk_size
  database_availability_type   = var.database_availability_type
  database_deletion_protection = var.database_deletion_protection
  database_password            = var.database_password
  readonly_database_password   = var.readonly_database_password
  
  depends_on = [
    module.networking
  ]
}

# =============================================================================
# Storage Module
# =============================================================================

module "storage" {
  source = "./modules/storage"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  
  # Storage configuration
  enable_bucket_versioning         = var.enable_bucket_versioning
  bucket_lifecycle_age_nearline    = var.bucket_lifecycle_age_nearline
  bucket_lifecycle_age_coldline    = var.bucket_lifecycle_age_coldline
  bucket_lifecycle_age_archive     = var.bucket_lifecycle_age_archive
  bucket_lifecycle_age_delete      = var.bucket_lifecycle_age_delete
  domain_name                      = var.domain_name
  
  # Required security dependencies - Fixed interface mapping
  application_data_key_id          = module.security.application_data_key_id
  terraform_service_account_email  = module.security.terraform_service_account_email
  gke_service_account_email        = module.security.gke_service_account_email
  
  depends_on = [
    module.security
  ]
}

# =============================================================================
# Monitoring Module
# =============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  
  # Core configuration
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  
  # Monitoring configuration
  alert_email             = var.alert_email
  gke_cluster_name        = module.gke.cluster_name
  database_instance_name  = module.database.instance_name
  
  depends_on = [
    module.gke,
    module.database
  ]
}