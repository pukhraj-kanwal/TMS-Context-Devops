# =============================================================================
# CargoLynx TMS - GKE Module
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# =============================================================================
# GKE Cluster
# =============================================================================

resource "google_container_cluster" "primary" {
  name     = "${var.environment}-gke-cluster"
  location = var.region
  
  # Remove default node pool since we'll create a custom one
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = var.vpc_network_name
  subnetwork = var.gke_subnet_name

  # IP allocation policy for VPC-native networking
  ip_allocation_policy {
    cluster_secondary_range_name  = var.gke_pods_secondary_range_name
    services_secondary_range_name = var.gke_services_secondary_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
    
    master_global_access_config {
      enabled = true
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled = true
  }

  # Master authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Autopilot mode (optional)
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      enabled = true
      
      resource_limits {
        resource_type = "cpu"
        minimum       = 1
        maximum       = var.gke_max_nodes * 4
      }
      
      resource_limits {
        resource_type = "memory"
        minimum       = 2
        maximum       = var.gke_max_nodes * 16
      }
    }
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
    
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T02:00:00Z"
      end_time   = "2024-01-01T06:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  # Binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  depends_on = [
    var.apis_enabled,
    var.vpc_network_id,
    var.gke_subnet_id
  ]

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_config
    ]
  }
}

# =============================================================================
# GKE Node Pool
# =============================================================================

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.environment}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  
  # Node count and autoscaling
  node_count = var.gke_node_count
  
  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  # Node configuration
  node_config {
    preemptible  = var.preemptible_node_pool
    spot         = var.spot_node_pool
    machine_type = var.gke_node_machine_type
    disk_size_gb = var.gke_node_disk_size
    disk_type    = "pd-ssd"
    image_type   = "COS_CONTAINERD"

    # Service account
    service_account = var.gke_service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Security and compliance
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Node taints
    dynamic "taint" {
      for_each = var.gke_node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Network tags
    tags = [
      "${var.environment}-gke-node",
      "allow-health-checks"
    ]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Local SSD count (for high I/O workloads)
    local_ssd_count = 0

    # Resource labels
    labels = {
      environment = var.environment
      managed-by  = "terraform"
      node-pool   = "${var.environment}-node-pool"
    }
  }

  # Node pool management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }


  depends_on = [
    google_container_cluster.primary
  ]

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}