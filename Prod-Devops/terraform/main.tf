# =============================================================================
# cargolynx TMS - Core Infrastructure Configuration
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

  # Remote state backend in GCS
  backend "gcs" {
    bucket = "cargolynx-tms-terraform-state"
    prefix = "infrastructure"
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    project     = "cargolynx-tms"
    environment = var.environment
    managed-by  = "terraform"
    team        = "platform-engineering"
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = {
    project     = "cargolynx-tms"
    environment = var.environment
    managed-by  = "terraform"
    team        = "platform-engineering"
  }
}

# =============================================================================
# Data Sources
# =============================================================================

data "google_client_config" "current" {}

data "google_project" "current" {
  project_id = var.project_id
}

# =============================================================================
# Local Values
# =============================================================================

locals {
  # Common resource naming
  name_prefix = "cargolynx-${var.environment}"
  short_prefix = "cargo-${substr(var.environment, 0, 4)}" # For service accounts (max 30 chars)
  
  # Network configuration
  vpc_name = "${local.name_prefix}-vpc"
  
  # Common labels
  common_labels = {
    project      = "cargolynx-tms"
    environment  = var.environment
    managed-by   = "terraform"
    team         = "platform-engineering"
    cost-center  = "engineering"
    component    = "infrastructure"
  }

  # GKE cluster configuration
  gke_cluster_name = "${local.name_prefix}"
  
  # Database configuration
  db_instance_name = "${local.name_prefix}-db"
}

# =============================================================================
# VPC Network Configuration
# =============================================================================

# Main VPC Network
resource "google_compute_network" "main" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
  
  # Security: Enable firewall logs
  enable_ula_internal_ipv6 = false
}

# Private subnet for GKE nodes
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${local.name_prefix}-gke-subnet"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.self_link

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true

  # Secondary IP ranges for GKE
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.gke_services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Private subnet for databases
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${local.name_prefix}-db-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.self_link

  private_ip_google_access = true
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "main" {
  name    = "${local.name_prefix}-router"
  region  = var.region
  network = google_compute_network.main.self_link
}

# NAT Gateway for outbound internet access
resource "google_compute_router_nat" "main" {
  name                               = "${local.name_prefix}-nat"
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# =============================================================================
# Firewall Rules
# =============================================================================

# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name_prefix}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
    var.database_subnet_cidr
  ]

  target_tags = ["cargolynx-tms-internal"]
}

# Allow health checks from Google Cloud Load Balancer
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.name_prefix}-allow-health-checks"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "30000-32767"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["cargolynx-tms-gke"]
}

# Allow HTTPS ingress
resource "google_compute_firewall" "allow_https" {
  name    = "${local.name_prefix}-allow-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["cargolynx-tms-https"]
}

# Deny all other external access (explicit deny)
resource "google_compute_firewall" "deny_all" {
  name      = "${local.name_prefix}-deny-all"
  network   = google_compute_network.main.name
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  
  # Exclude internal and health check ranges
  destination_ranges = ["0.0.0.0/0"]
}

# =============================================================================
# Service Accounts and IAM
# =============================================================================

# GKE Service Account
resource "google_service_account" "gke_service_account" {
  account_id   = "${local.short_prefix}-gke-sa"
  display_name = "cargolynx TMS GKE Service Account"
  description  = "Service account for GKE cluster nodes"
}

# GKE Service Account IAM bindings
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/container.nodeServiceAccount"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}

# Terraform Service Account for infrastructure management
resource "google_service_account" "terraform_service_account" {
  account_id   = "${local.short_prefix}-tf-sa"
  display_name = "cargolynx TMS Terraform Service Account"
  description  = "Service account for Terraform infrastructure management"
}

# Terraform Service Account IAM bindings
resource "google_project_iam_member" "terraform_service_account_roles" {
  for_each = toset([
    "roles/compute.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
}

# =============================================================================
# Google Kubernetes Engine (GKE) Cluster
# =============================================================================

# Private GKE Cluster - Working Configuration
resource "google_container_cluster" "main" {
  name     = local.gke_cluster_name
  location = var.region

  # Network configuration
  network    = google_compute_network.main.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Workload Identity for secure service-to-service auth
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Remove default node pool for custom node pools
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_project_iam_member.gke_service_account_roles
  ]
}

# Standard node pool for production workloads
resource "google_container_node_pool" "standard_pool" {
  count = var.enable_gke_autopilot ? 0 : 1
  
  name       = "standard-pool"
  location   = var.region
  cluster    = google_container_cluster.main.name
  node_count = var.gke_node_count

  # Node configuration
  node_config {
    preemptible  = false
    machine_type = var.gke_node_machine_type
    disk_size_gb = var.gke_node_disk_size
    disk_type    = "pd-ssd"

    # Security configuration
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Image type with security updates
    image_type = "COS_CONTAINERD"

    # Enable secure boot and integrity monitoring
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Network tags for firewall rules
    tags = ["cargolynx-tms-gke", "cargolynx-tms-internal"]

    # Workload metadata configuration
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Resource labels
    labels = merge(local.common_labels, {
      node-pool = "standard"
    })

    

    # Node taints for workload scheduling
    dynamic "taint" {
      for_each = var.gke_node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Auto-scaling configuration
  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  # Auto-upgrade and auto-repair
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  depends_on = [
    google_container_cluster.main
  ]
}

# =============================================================================
# Cloud SQL Database
# =============================================================================

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "main" {
  name             = local.db_instance_name
  database_version = var.database_version
  region           = var.region

  settings {
    tier                        = var.database_tier
    disk_size                   = var.database_disk_size
    disk_type                   = "PD_SSD"
    disk_autoresize            = true
    disk_autoresize_limit      = var.database_max_disk_size
    availability_type          = var.database_availability_type
    deletion_protection_enabled = var.database_deletion_protection

    # IP configuration for private access
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.self_link
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3  # 3 AM
      update_track = "stable"
    }

    # Monitoring and logging
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # Database flags for performance and security
    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_statement"
      value = "ddl"
    }

    # User labels
    user_labels = local.common_labels
  }

  # Prevent accidental deletion
  deletion_protection = var.database_deletion_protection

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

# Private services access for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${local.name_prefix}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Main application database
resource "google_sql_database" "cargolynx_tms" {
  name     = "cargolynx_tms"
  instance = google_sql_database_instance.main.name
  charset  = "UTF8"
  collation = "en_US.UTF8"
}

# Database user for applications (password managed via Secret Manager)
resource "google_sql_user" "app_user" {
  name     = "cargolynx_app"
  instance = google_sql_database_instance.main.name
  type     = "BUILT_IN"
  password_wo = var.database_password  # Should be provided via secret
}

# =============================================================================
# Cloud Storage Buckets
# =============================================================================

# Terraform state bucket (already referenced in backend)
resource "google_storage_bucket" "terraform_state" {
  name          = "cargolynx-tms-terraform-state"
  location      = var.region
  storage_class = "STANDARD"

  # Versioning for state file safety
  versioning {
    enabled = true
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Security settings
  uniform_bucket_level_access = true
  
  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state_key.id
  }

  labels = local.common_labels
}

# Application data bucket
resource "google_storage_bucket" "app_data" {
  name          = "${local.name_prefix}-app-data"
  location      = var.region
  storage_class = "STANDARD"

  # Versioning for data safety
  versioning {
    enabled = true
  }

  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 2555  # 7 years
    }
    action {
      type = "Delete"
    }
  }

  # Security settings
  uniform_bucket_level_access = true

  # CORS configuration for web access
  cors {
    origin          = ["https://*.cargolynx-tms.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = local.common_labels
}

# =============================================================================
# Cloud KMS for Encryption
# =============================================================================

# KMS Key Ring
resource "google_kms_key_ring" "main" {
  name     = "${local.name_prefix}-keyring"
  location = var.region
}

# Terraform state encryption key
resource "google_kms_crypto_key" "terraform_state_key" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.main.id

  rotation_period = "2592000s"  # 30 days

  lifecycle {
    prevent_destroy = true
  }

  labels = local.common_labels
}

# Application data encryption key
resource "google_kms_crypto_key" "app_data_key" {
  name     = "app-data-key"
  key_ring = google_kms_key_ring.main.id

  rotation_period = "2592000s"  # 30 days

  lifecycle {
    prevent_destroy = true
  }

  labels = local.common_labels
}

# =============================================================================
# Cloud Monitoring and Alerting
# =============================================================================

# Notification channel for alerts
resource "google_monitoring_notification_channel" "email" {
  display_name = "Platform Team Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# Uptime check for health monitoring
resource "google_monitoring_uptime_check_config" "api_health" {
  display_name = "cargolynx TMS API Health Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/health"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "api.${var.domain_name}"
    }
  }
}

# Alert policy for high CPU usage (will be configured after cluster deployment)
# resource "google_monitoring_alert_policy" "high_cpu_usage" {
#   display_name = "High CPU Usage"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "CPU usage > 80%"
#
#     condition_threshold {
#       filter          = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\""
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0.8
#
#       aggregations {
#         alignment_period     = "60s"
#         per_series_aligner   = "ALIGN_RATE"
#         cross_series_reducer = "REDUCE_MEAN"
#         group_by_fields      = ["resource.labels.container_name"]
#       }
#     }
#   }
#
#   notification_channels = [
#     google_monitoring_notification_channel.email.name
#   ]
#
#   alert_strategy {
#     auto_close = "86400s"  # 24 hours
#   }
# }