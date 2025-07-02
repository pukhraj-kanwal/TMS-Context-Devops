# CargoLynx TMS - Staging Environment Configuration
# Production-like environment for final validation with cost optimizations

terraform {
  required_version = ">= 1.5"
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
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }

  # Backend configuration handled via backend config file during deployment
  # For validation testing, local state is used
}

# Local variables for staging environment
locals {
  environment = "staging"
  region      = var.region
  project_id  = var.project_id
  
  # Cost optimization flags
  use_preemptible_nodes = true
  enable_auto_shutdown  = true
  
  # Staging-specific configurations
  min_node_count = 1
  max_node_count = 6
  default_node_count = 2
  
  # Production-like but cost-optimized resource sizing
  machine_types = {
    gke_nodes = "e2-standard-2"  # Smaller than production but adequate
    database  = "db-custom-2-7680"  # 2 vCPU, 7.5 GB RAM
  }
  
  # Storage optimizations for staging
  storage_classes = {
    application_data = "STANDARD"
    backups         = "NEARLINE"
    logs           = "COLDLINE"
    temp           = "STANDARD"
  }
  
  # Monitoring with reduced retention for cost savings
  monitoring_config = {
    metrics_retention_days = 30    # vs 90 for production
    logs_retention_days    = 14    # vs 30 for production
    enable_detailed_monitoring = true
    alert_channels = ["email", "slack"]
  }
  
  # Security settings (production-like)
  security_config = {
    enable_private_cluster     = true
    enable_network_policy      = true
    enable_workload_identity   = true
    enable_pod_security_policy = true
    master_ipv4_cidr_block    = "172.16.0.0/28"
    
    # Key rotation (more frequent than production for testing)
    kms_key_rotation_period = "2592000s"  # 30 days
  }
  
  # Database configuration
  database_config = {
    tier                = local.machine_types.database
    disk_size          = 50  # Smaller than production
    disk_type          = "PD_SSD"
    availability_type  = "ZONAL"  # Cost optimization vs REGIONAL
    backup_enabled     = true
    point_in_time_recovery = true
    
    # Maintenance window during low-usage hours
    maintenance_window = {
      day          = 1  # Sunday
      hour         = 6  # 6 AM UTC
      update_track = "stable"
    }
    
    # Database flags for optimization
    database_flags = [
      {
        name  = "shared_preload_libraries"
        value = "pg_stat_statements"
      },
      {
        name  = "track_activity_query_size"
        value = "2048"
      },
      {
        name  = "pg_stat_statements.track"
        value = "all"
      }
    ]
  }
  
  # Network configuration
  network_config = {
    vpc_cidr_range     = "10.2.0.0/16"  # Different from other environments
    gke_subnet_cidr    = "10.2.1.0/24"
    services_cidr      = "10.2.16.0/20"
    cluster_cidr       = "10.2.32.0/20"
    
    # Enable Cloud NAT for outbound internet access
    enable_cloud_nat = true
    nat_ip_allocate_option = "MANUAL_ONLY"
    nat_addresses_count = 1
  }
  
  # Application configuration
  application_config = {
    namespace = "cargolynx-staging"
    domain    = var.staging_domain
    
    # SSL configuration
    ssl_config = {
      enable_ssl = true
      ssl_policy = "RESTRICTED"
    }
    
    # Load balancer configuration
    load_balancer = {
      type = "EXTERNAL"
      ip_version = "IPV4"
    }
  }
  
  # Tagging strategy
  labels = {
    environment   = local.environment
    project      = "cargolynx-tms"
    team         = "devops"
    cost-center  = "engineering"
    purpose      = "staging-validation"
    auto-shutdown = "enabled"
  }
}

# Configure providers
provider "google" {
  project = local.project_id
  region  = local.region
}

provider "google-beta" {
  project = local.project_id
  region  = local.region
}

# Main infrastructure module
module "cargolynx_infrastructure" {
  source = "../../modules/gcp-infrastructure"
  
  # Core Configuration (Required)
  project_id  = local.project_id
  environment = local.environment
  region      = local.region
  
  # Domain Configuration (Required)
  domain_name = "staging.cargolynx.com"
  
  # Network Configuration (Required)
  gke_subnet_cidr       = local.network_config.gke_subnet_cidr
  gke_pods_cidr         = local.network_config.services_cidr
  gke_services_cidr     = local.network_config.cluster_cidr
  database_subnet_cidr  = "10.2.2.0/24"
  
  # GKE Configuration (Required)
  gke_node_machine_type = local.machine_types.gke_nodes
  gke_node_disk_size    = 50
  gke_node_count        = local.default_node_count
  gke_min_nodes         = local.min_node_count
  gke_max_nodes         = local.max_node_count
  preemptible_node_pool = local.use_preemptible_nodes
  spot_node_pool        = false
  
  # Database Configuration (Required)
  database_tier              = "db-custom-2-7680"
  database_disk_size         = local.database_config.disk_size
  database_max_disk_size     = 100
  database_version           = "POSTGRES_15"
  database_password          = "staging-password-456"
  readonly_database_password = "staging-readonly-456"
  database_deletion_protection = false
  database_availability_type = local.database_config.availability_type
  
  # Storage Configuration (Required)
  enable_bucket_versioning       = true
  bucket_lifecycle_age_nearline  = 7
  bucket_lifecycle_age_coldline  = 30
  bucket_lifecycle_age_archive   = 90
  bucket_lifecycle_age_delete    = 365
  
  # Monitoring Configuration (Required)
  alert_email = "alerts@cargolynx.com"
  
  # Cost Center Configuration (Required)
  cost_center = "engineering"
}

# Configure Kubernetes provider after cluster creation
provider "kubernetes" {
  host                   = module.cargolynx_infrastructure.gke_cluster_endpoint
  cluster_ca_certificate = base64decode(module.cargolynx_infrastructure.gke_cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.cargolynx_infrastructure.gke_cluster_endpoint
    cluster_ca_certificate = base64decode(module.cargolynx_infrastructure.gke_cluster_ca_certificate)
  }
}

# Create staging-specific namespace
resource "kubernetes_namespace" "staging" {
  metadata {
    name = local.application_config.namespace
    labels = merge(local.labels, {
      name = local.application_config.namespace
      tier = "application"
    })
    annotations = {
      "scheduler.alpha.kubernetes.io/node-selector" = "environment=staging"
    }
  }

  depends_on = [module.cargolynx_infrastructure]
}

# Create staging-specific secret for database connection
resource "kubernetes_secret" "database_credentials" {
  metadata {
    name      = "database-credentials"
    namespace = kubernetes_namespace.staging.metadata[0].name
    labels    = local.labels
  }

  data = {
    host     = module.cargolynx_infrastructure.database_private_ip
    port     = "5432"
    database = module.cargolynx_infrastructure.database_name
    username = module.cargolynx_infrastructure.database_user
    password = "staging-password-456"
  }

  type = "Opaque"
}

# Create staging-specific service account
resource "kubernetes_service_account" "staging_app" {
  metadata {
    name      = "cargolynx-staging-app"
    namespace = kubernetes_namespace.staging.metadata[0].name
    labels    = local.labels
    annotations = {
      "iam.gke.io/gcp-service-account" = module.cargolynx_infrastructure.gke_service_account_email
    }
  }
}

# Create staging-specific network policies
resource "kubernetes_network_policy" "staging_isolation" {
  count = local.security_config.enable_network_policy ? 1 : 0

  metadata {
    name      = "staging-isolation"
    namespace = kubernetes_namespace.staging.metadata[0].name
    labels    = local.labels
  }

  spec {
    pod_selector {}
    
    policy_types = ["Ingress", "Egress"]
    
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = local.application_config.namespace
          }
        }
      }
    }
    
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = local.application_config.namespace
          }
        }
      }
      
      # Allow egress to kube-system for DNS
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }
  }
}