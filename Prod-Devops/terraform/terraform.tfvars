# =============================================================================
# CargoLynx TMS - Terraform Variables (Production Environment)
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Project Configuration
# =============================================================================
project_id  = "cargolynx-main"
region      = "us-central1"
zone        = "us-central1-a"
environment = "production"

# =============================================================================
# Network Configuration
# =============================================================================
gke_subnet_cidr      = "10.1.0.0/24"
gke_pods_cidr        = "10.2.0.0/16"
gke_services_cidr    = "10.3.0.0/16"
gke_master_cidr      = "10.4.0.0/28"
database_subnet_cidr = "10.5.0.0/24"

# =============================================================================
# GKE Configuration - Production Settings
# =============================================================================
enable_gke_autopilot    = false
gke_node_zones         = ["us-central1-a", "us-central1-b", "us-central1-c"]
gke_node_machine_type  = "e2-standard-2"  # 2 vCPU, 8GB RAM - quota friendly
gke_node_disk_size     = 50               # 50GB to stay within quotas
gke_node_count         = 2                # Start with 2 nodes (4 vCPUs total)
gke_min_nodes          = 1                # Minimum 1 node
gke_max_nodes          = 10               # Reduced max for quota limits

# Node taints for production workloads
gke_node_taints = []

# =============================================================================
# Database Configuration - Production Settings
# =============================================================================
database_version           = "POSTGRES_15"
database_tier             = "db-custom-4-16384"  # 4 vCPUs, 16GB RAM
database_disk_size        = 200                   # 200GB initial
database_max_disk_size    = 2000                  # 2TB max auto-resize
database_availability_type = "REGIONAL"           # High availability
database_deletion_protection = true

# Database password should be set via environment variable:
# export TF_VAR_database_password="your-secure-password-here"
database_password = "CargoLynx2025!Secure#DB$Pass"

# =============================================================================
# Security Configuration - Production Settings
# =============================================================================
enable_binary_authorization = true
enable_network_policy      = true
enable_workload_identity    = true
enable_shielded_nodes      = true

# =============================================================================
# Monitoring and Alerting Configuration
# =============================================================================
alert_email               = "platform-team@cargolynx.com"
enable_managed_prometheus = true
enable_workload_metrics   = true

# =============================================================================
# Storage Configuration - Production Settings
# =============================================================================
enable_bucket_versioning        = true
bucket_lifecycle_age_nearline   = 30   # 30 days to Nearline
bucket_lifecycle_age_coldline   = 90   # 90 days to Coldline
bucket_lifecycle_age_archive    = 365  # 1 year to Archive
bucket_lifecycle_age_delete     = 2555 # 7 years retention

# =============================================================================
# Domain and DNS Configuration
# =============================================================================
domain_name            = "cargolynx.com"
enable_ssl_certificates = true
enable_cdn             = true

# =============================================================================
# Cost Management Configuration
# =============================================================================
enable_cost_optimization   = true
preemptible_node_pool      = false  # Production should use standard nodes
spot_node_pool             = false  # Production should use standard nodes
enable_cluster_autoscaling = true

# =============================================================================
# Compliance Configuration - Production Settings
# =============================================================================
enable_audit_logs           = true
enable_vpc_flow_logs        = true
enable_data_loss_prevention = true
compliance_mode             = "standard"

# =============================================================================
# Backup and Disaster Recovery Configuration
# =============================================================================
backup_retention_days         = 30    # 30 days retention
enable_point_in_time_recovery = true
cross_region_backup          = true
backup_schedule              = "0 3 * * *"  # Daily at 3 AM UTC

# =============================================================================
# Development and Testing Configuration
# =============================================================================
enable_dev_environments = false  # Production environment
dev_node_machine_type   = "e2-standard-2"
dev_max_nodes          = 3

# =============================================================================
# Resource Tagging Configuration
# =============================================================================
additional_labels = {
  "project"           = "cargolynx-tms"
  "platform"          = "autonomous-logistics"
  "deployment-method" = "terraform"
  "team"              = "platform-engineering"
  "criticality"       = "high"
  "data-classification" = "confidential"
}

cost_center    = "engineering"
owner_team     = "platform-engineering"
business_unit  = "technology"

# =============================================================================
# Feature Flags - Production Settings
# =============================================================================
enable_experimental_features = false  # Disabled in production
enable_debug_mode           = false   # Disabled in production
enable_maintenance_mode     = false

# =============================================================================
# Integration Configuration
# =============================================================================
enable_istio_service_mesh        = false  # Can be enabled later
enable_knative_serving          = false  # Can be enabled later
enable_anthos_config_management = false  # Can be enabled later

# =============================================================================
# Performance Configuration
# =============================================================================
enable_horizontal_pod_autoscaling    = true
enable_vertical_pod_autoscaling      = true
enable_cluster_autoscaling_profiles  = true

# Node pool surge settings for zero-downtime updates
node_pool_surge_settings = {
  max_surge       = 1
  max_unavailable = 0
}