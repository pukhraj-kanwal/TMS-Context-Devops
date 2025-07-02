# CargoLynx TMS - UAT Environment Configuration
# User Acceptance Testing environment optimized for business validation

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

  # Local backend for UAT environment testing
  # Note: Switch to GCS backend after successful validation
}

# Local variables for UAT environment
locals {
  environment = "uat"
  region      = var.region
  project_id  = var.project_id
  
  # UAT-specific optimizations
  use_preemptible_nodes = false  # Stability for user testing
  enable_auto_shutdown  = false  # Keep running for business hours
  
  # UAT resource sizing (balanced for stability and cost)
  min_node_count = 1
  max_node_count = 4
  default_node_count = 2
  
  # Stable resource sizing for consistent user experience
  machine_types = {
    gke_nodes = "e2-standard-2"    # Consistent performance
    database  = "db-custom-2-7680" # 2 vCPU, 7.5 GB RAM
  }
  
  # Storage optimized for UAT workflows
  storage_classes = {
    application_data = "STANDARD"
    backups         = "NEARLINE"
    logs           = "STANDARD"     # Keep logs accessible for debugging
    temp           = "STANDARD"
    user_uploads   = "STANDARD"     # User testing files
  }
  
  # Monitoring optimized for user testing
  monitoring_config = {
    metrics_retention_days = 60    # Longer retention for UAT analysis
    logs_retention_days    = 30    # Extended for user issue tracking
    enable_detailed_monitoring = true
    alert_channels = ["email", "slack", "webhook"]
    
    # UAT-specific SLAs
    availability_target = 99.0     # Relaxed vs production 99.9%
    latency_target_ms  = 2000     # Relaxed vs production 500ms
    error_rate_target  = 1.0      # 1% vs production 0.1%
  }
  
  # Security configuration (production-like for business data)
  security_config = {
    enable_private_cluster     = true
    enable_network_policy      = true
    enable_workload_identity   = true
    enable_pod_security_policy = true
    master_ipv4_cidr_block    = "172.17.0.0/28"
    
    # Standard security rotation
    kms_key_rotation_period = "7776000s"  # 90 days
    
    # UAT-specific security features
    enable_audit_logging      = true
    enable_access_transparency = true
    enable_binary_authorization = false  # May interfere with testing
  }
  
  # Database configuration optimized for UAT
  database_config = {
    tier                = local.machine_types.database
    disk_size          = 100  # Larger for test data
    disk_type          = "PD_SSD"
    availability_type  = "ZONAL"  # Cost optimization
    backup_enabled     = true
    point_in_time_recovery = true
    
    # Maintenance during low-usage hours
    maintenance_window = {
      day          = 7   # Saturday
      hour         = 4   # 4 AM UTC
      update_track = "stable"
    }
    
    # Database optimization for UAT workloads
    database_flags = [
      {
        name  = "shared_preload_libraries"
        value = "pg_stat_statements,pg_hint_plan"
      },
      {
        name  = "track_activity_query_size"
        value = "4096"
      },
      {
        name  = "pg_stat_statements.track"
        value = "all"
      },
      {
        name  = "log_statement"
        value = "all"  # Full logging for UAT debugging
      },
      {
        name  = "log_duration"
        value = "on"
      }
    ]
  }
  
  # Network configuration
  network_config = {
    vpc_cidr_range     = "10.3.0.0/16"  # Unique range for UAT
    gke_subnet_cidr    = "10.3.1.0/24"
    services_cidr      = "10.3.16.0/20"
    cluster_cidr       = "10.3.32.0/20"
    
    # Enable Cloud NAT for external integrations
    enable_cloud_nat = true
    nat_ip_allocate_option = "MANUAL_ONLY"
    nat_addresses_count = 2  # Redundancy for UAT
    
    # Private Google Access for UAT services
    enable_private_google_access = true
  }
  
  # UAT-specific application configuration
  application_config = {
    namespace = "cargolynx-uat"
    domain    = var.uat_domain
    
    # SSL configuration
    ssl_config = {
      enable_ssl = true
      ssl_policy = "MODERN"  # Latest SSL for security testing
    }
    
    # Load balancer with UAT-specific features
    load_balancer = {
      type = "EXTERNAL"
      ip_version = "IPV4"
      enable_cdn = false  # Direct access for testing
      enable_logging = true
    }
    
    # UAT-specific features
    enable_debug_mode = true
    enable_detailed_logging = true
    enable_performance_profiling = true
  }
  
  # User testing configuration
  user_testing_config = {
    enable_test_user_management = true
    enable_session_recording   = var.enable_session_recording
    enable_analytics_tracking  = true
    enable_feedback_collection = true
    
    # Test data management
    enable_test_data_refresh   = true
    test_data_source          = "staging"
    data_refresh_schedule     = "0 2 * * 1"  # Monday 2 AM
    
    # User access management
    max_concurrent_users = 50
    session_timeout_minutes = 60
    enable_user_isolation = true
  }
  
  # Integration testing for UAT
  integration_config = {
    enable_external_api_testing = true
    enable_payment_gateway_testing = true
    enable_notification_testing = true
    enable_reporting_validation = true
    
    # Third-party integrations for UAT
    external_services = [
      "stripe-test",
      "twilio-test", 
      "sendgrid-test",
      "google-maps-api"
    ]
  }
  
  # Tagging strategy for UAT
  labels = {
    environment   = local.environment
    project      = "cargolynx-tms"
    team         = "product"
    cost-center  = "business-validation"
    purpose      = "user-acceptance-testing"
    auto-shutdown = "disabled"
    data-classification = "test"
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

  # Basic configuration (required)
  project_id  = local.project_id
  region      = local.region
  environment = local.environment

  # Network configuration (required)
  gke_subnet_cidr       = local.network_config.gke_subnet_cidr
  gke_services_cidr     = local.network_config.services_cidr
  gke_pods_cidr         = local.network_config.cluster_cidr
  database_subnet_cidr  = "10.3.2.0/24"

  # GKE configuration (required)
  gke_node_machine_type = local.machine_types.gke_nodes
  gke_node_count        = local.default_node_count
  gke_min_nodes         = local.min_node_count
  gke_max_nodes         = local.max_node_count
  gke_node_disk_size    = 30
  preemptible_node_pool = local.use_preemptible_nodes
  spot_node_pool        = false

  # Database configuration (required)
  database_tier                = local.database_config.tier
  database_disk_size           = local.database_config.disk_size
  database_max_disk_size       = 200
  database_availability_type   = local.database_config.availability_type
  database_version             = "POSTGRES_15"
  database_deletion_protection = false
  database_password            = "uat-password-789"

  # Required fields
  domain_name = "uat.cargolynx.com"
  alert_email = "devops@cargolynx.com"
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

# Create UAT-specific namespace
resource "kubernetes_namespace" "uat" {
  metadata {
    name = local.application_config.namespace
    labels = merge(local.labels, {
      name = local.application_config.namespace
      tier = "application"
      testing-type = "user-acceptance"
    })
    annotations = {
      "scheduler.alpha.kubernetes.io/node-selector" = "environment=uat"
      "testing.cargolynx.com/user-access" = "enabled"
      "monitoring.cargolynx.com/detailed-logging" = "enabled"
    }
  }

  depends_on = [module.cargolynx_infrastructure]
}

# Create UAT-specific secret for database connection
resource "kubernetes_secret" "database_credentials" {
  metadata {
    name      = "database-credentials"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = local.labels
  }

  data = {
    host     = module.cargolynx_infrastructure.database_private_ip
    port     = "5432"
    database = module.cargolynx_infrastructure.database_name
    username = module.cargolynx_infrastructure.database_user
    password = "uat-password-789"  # Hardcoded for testing validation
  }

  type = "Opaque"
}

# Create UAT-specific service account
resource "kubernetes_service_account" "uat_app" {
  metadata {
    name      = "cargolynx-uat-app"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = local.labels
    annotations = {
      "iam.gke.io/gcp-service-account" = module.cargolynx_infrastructure.gke_service_account_email
    }
  }
}

# Create UAT user testing service account
resource "kubernetes_service_account" "uat_testing" {
  metadata {
    name      = "cargolynx-uat-testing"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = merge(local.labels, {
      purpose = "user-testing"
    })
    annotations = {
      "testing.cargolynx.com/user-session-management" = "enabled"
      "testing.cargolynx.com/analytics-collection" = "enabled"
    }
  }
}

# Create UAT-specific network policies
resource "kubernetes_network_policy" "uat_isolation" {
  count = local.security_config.enable_network_policy ? 1 : 0

  metadata {
    name      = "uat-isolation"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = local.labels
  }

  spec {
    pod_selector {}
    
    policy_types = ["Ingress", "Egress"]
    
    ingress {
      # Allow ingress from load balancer
      from {
        namespace_selector {
          match_labels = {
            name = "gke-system"
          }
        }
      }
      
      # Allow ingress within UAT namespace
      from {
        namespace_selector {
          match_labels = {
            name = local.application_config.namespace
          }
        }
      }
    }
    
    egress {
      # Allow egress within UAT namespace
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
      
      # Allow egress to external APIs for testing
      to {}
      ports {
        protocol = "TCP"
        port     = "443"
      }
      ports {
        protocol = "TCP"
        port     = "80"
      }
    }
  }
}

# Create UAT-specific ConfigMap for application configuration
resource "kubernetes_config_map" "uat_config" {
  metadata {
    name      = "cargolynx-uat-config"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = local.labels
  }

  data = {
    ENVIRONMENT                = local.environment
    DEBUG_MODE                = tostring(local.application_config.enable_debug_mode)
    DETAILED_LOGGING          = tostring(local.application_config.enable_detailed_logging)
    PERFORMANCE_PROFILING     = tostring(local.application_config.enable_performance_profiling)
    
    # User testing configuration
    ENABLE_SESSION_RECORDING  = tostring(local.user_testing_config.enable_session_recording)
    ENABLE_ANALYTICS_TRACKING = tostring(local.user_testing_config.enable_analytics_tracking)
    ENABLE_FEEDBACK_COLLECTION = tostring(local.user_testing_config.enable_feedback_collection)
    MAX_CONCURRENT_USERS      = tostring(local.user_testing_config.max_concurrent_users)
    SESSION_TIMEOUT_MINUTES   = tostring(local.user_testing_config.session_timeout_minutes)
    
    # External service endpoints for testing
    STRIPE_API_ENDPOINT       = "https://api.stripe.com/v1"
    TWILIO_API_ENDPOINT       = "https://api.twilio.com/2010-04-01"
    SENDGRID_API_ENDPOINT     = "https://api.sendgrid.com/v3"
    GOOGLE_MAPS_API_ENDPOINT  = "https://maps.googleapis.com/maps/api"
    
    # UAT-specific feature flags
    ENABLE_TEST_DATA_REFRESH  = tostring(local.user_testing_config.enable_test_data_refresh)
    ENABLE_USER_ISOLATION     = tostring(local.user_testing_config.enable_user_isolation)
  }
}

# Create UAT-specific resource quotas
resource "kubernetes_resource_quota" "uat_quota" {
  metadata {
    name      = "uat-resource-quota"
    namespace = kubernetes_namespace.uat.metadata[0].name
    labels    = local.labels
  }

  spec {
    hard = {
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "16Gi"
      "pods"           = "20"
      "services"       = "10"
      "persistentvolumeclaims" = "5"
    }
  }
}

# Create UAT-specific priority class for testing workloads
resource "kubernetes_priority_class" "uat_priority" {
  metadata {
    name   = "uat-priority"
    labels = local.labels
  }

  value          = 100
  global_default = false
  description    = "Priority class for UAT testing workloads"
}