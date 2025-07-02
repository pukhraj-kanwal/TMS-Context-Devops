# =============================================================================
# CargoLynx TMS - Terraform Variables Configuration
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Project Configuration
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "cargolynx-main"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development", "sandbox"], var.environment)
    error_message = "Environment must be one of: production, staging, development, sandbox."
  }
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.2.0.0/16"
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.3.0.0/16"
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master nodes"
  type        = string
  default     = "10.4.0.0/28"
}

variable "database_subnet_cidr" {
  description = "CIDR range for database subnet"
  type        = string
  default     = "10.5.0.0/24"
}

# =============================================================================
# GKE Configuration
# =============================================================================

variable "enable_gke_autopilot" {
  description = "Enable GKE Autopilot mode for simplified management"
  type        = bool
  default     = false
}

variable "gke_node_zones" {
  description = "List of zones for GKE nodes"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "n2-standard-4"
  
  validation {
    condition = can(regex("^(n2|e2|c2|m1)-(standard|highmem|highcpu)-[0-9]+$", var.gke_node_machine_type))
    error_message = "Machine type must be a valid GCP machine type (e.g., n2-standard-4)."
  }
}

variable "gke_node_disk_size" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 100
  
  validation {
    condition     = var.gke_node_disk_size >= 20 && var.gke_node_disk_size <= 1000
    error_message = "Node disk size must be between 20 and 1000 GB."
  }
}

variable "gke_node_count" {
  description = "Initial number of nodes in the GKE node pool"
  type        = number
  default     = 3
  
  validation {
    condition     = var.gke_node_count >= 1 && var.gke_node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "gke_min_nodes" {
  description = "Minimum number of nodes in the GKE node pool"
  type        = number
  default     = 1
  
  validation {
    condition     = var.gke_min_nodes >= 0 && var.gke_min_nodes <= 50
    error_message = "Minimum nodes must be between 0 and 50."
  }
}

variable "gke_max_nodes" {
  description = "Maximum number of nodes in the GKE node pool"
  type        = number
  default     = 10
  
  validation {
    condition     = var.gke_max_nodes >= 1 && var.gke_max_nodes <= 100
    error_message = "Maximum nodes must be between 1 and 100."
  }
}

variable "gke_node_taints" {
  description = "List of taints to apply to GKE nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
  
  validation {
    condition = alltrue([
      for taint in var.gke_node_taints :
      contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], taint.effect)
    ])
    error_message = "Taint effect must be one of: NoSchedule, PreferNoSchedule, NoExecute."
  }
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "database_version" {
  description = "PostgreSQL version for Cloud SQL"
  type        = string
  default     = "POSTGRES_15"
  
  validation {
    condition = can(regex("^POSTGRES_[0-9]+$", var.database_version))
    error_message = "Database version must be a valid PostgreSQL version (e.g., POSTGRES_15)."
  }
}

variable "database_tier" {
  description = "Machine type for Cloud SQL instance"
  type        = string
  default     = "db-custom-4-16384"
  
  validation {
    condition = can(regex("^db-(custom|standard|highmem)-[0-9]+-[0-9]+$", var.database_tier))
    error_message = "Database tier must be a valid Cloud SQL machine type."
  }
}

variable "database_disk_size" {
  description = "Disk size for Cloud SQL instance in GB"
  type        = number
  default     = 100
  
  validation {
    condition     = var.database_disk_size >= 20 && var.database_disk_size <= 10000
    error_message = "Database disk size must be between 20 and 10000 GB."
  }
}

variable "database_max_disk_size" {
  description = "Maximum disk size for auto-resize in GB"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.database_max_disk_size >= var.database_disk_size
    error_message = "Maximum disk size must be greater than or equal to initial disk size."
  }
}

variable "database_availability_type" {
  description = "Availability type for Cloud SQL (ZONAL or REGIONAL)"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.database_availability_type)
    error_message = "Database availability type must be either ZONAL or REGIONAL."
  }
}

variable "database_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL instance"
  type        = bool
  default     = true
}

variable "database_password" {
  description = "Password for the database user (should be provided via secret)"
  type        = string
  sensitive   = true
  default     = ""
  
  validation {
    condition     = length(var.database_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# =============================================================================
# Security Configuration
# =============================================================================

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for container image security"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Kubernetes Network Policy"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for secure pod-to-GCP auth"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable shielded GKE nodes for enhanced security"
  type        = bool
  default     = true
}

# =============================================================================
# Monitoring and Alerting Configuration
# =============================================================================

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "platform-team@company.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Prometheus"
  type        = bool
  default     = true
}

variable "enable_workload_metrics" {
  description = "Enable workload metrics collection"
  type        = bool
  default     = true
}

# =============================================================================
# Storage Configuration
# =============================================================================

variable "enable_bucket_versioning" {
  description = "Enable versioning for Cloud Storage buckets"
  type        = bool
  default     = true
}

variable "bucket_lifecycle_age_nearline" {
  description = "Age in days before transitioning to Nearline storage"
  type        = number
  default     = 30
  
  validation {
    condition     = var.bucket_lifecycle_age_nearline >= 0 && var.bucket_lifecycle_age_nearline <= 365
    error_message = "Nearline transition age must be between 0 and 365 days."
  }
}

variable "bucket_lifecycle_age_coldline" {
  description = "Age in days before transitioning to Coldline storage"
  type        = number
  default     = 90
  
  validation {
    condition     = var.bucket_lifecycle_age_coldline >= var.bucket_lifecycle_age_nearline
    error_message = "Coldline transition age must be greater than or equal to Nearline transition age."
  }
}

variable "bucket_lifecycle_age_archive" {
  description = "Age in days before transitioning to Archive storage"
  type        = number
  default     = 365
  
  validation {
    condition     = var.bucket_lifecycle_age_archive >= var.bucket_lifecycle_age_coldline
    error_message = "Archive transition age must be greater than or equal to Coldline transition age."
  }
}

variable "bucket_lifecycle_age_delete" {
  description = "Age in days before deleting objects (7 years = 2555 days)"
  type        = number
  default     = 2555
  
  validation {
    condition     = var.bucket_lifecycle_age_delete >= var.bucket_lifecycle_age_archive
    error_message = "Delete age must be greater than or equal to Archive transition age."
  }
}

# =============================================================================
# Domain and DNS Configuration
# =============================================================================

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
  default     = "gemini-tms.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_ssl_certificates" {
  description = "Enable managed SSL certificates"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for static content"
  type        = bool
  default     = true
}

# =============================================================================
# Cost Management Configuration
# =============================================================================

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "preemptible_node_pool" {
  description = "Enable preemptible node pool for cost savings"
  type        = bool
  default     = false
}

variable "spot_node_pool" {
  description = "Enable spot instance node pool for cost savings"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaling" {
  description = "Enable cluster-level autoscaling"
  type        = bool
  default     = true
}

# =============================================================================
# Compliance Configuration
# =============================================================================

variable "enable_audit_logs" {
  description = "Enable audit logging for compliance"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "enable_data_loss_prevention" {
  description = "Enable Cloud DLP for data protection"
  type        = bool
  default     = true
}

variable "compliance_mode" {
  description = "Compliance mode (standard, sox, hipaa, pci)"
  type        = string
  default     = "standard"
  
  validation {
    condition     = contains(["standard", "sox", "hipaa", "pci"], var.compliance_mode)
    error_message = "Compliance mode must be one of: standard, sox, hipaa, pci."
  }
}

# =============================================================================
# Backup and Disaster Recovery Configuration
# =============================================================================

variable "backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for database"
  type        = bool
  default     = true
}

variable "cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron schedule for automated backups"
  type        = string
  default     = "0 3 * * *"  # Daily at 3 AM
  
  validation {
    condition     = can(regex("^([0-9*,-/]+\\s+){4}[0-9*,-/]+$", var.backup_schedule))
    error_message = "Backup schedule must be a valid cron expression."
  }
}

# =============================================================================
# Development and Testing Configuration
# =============================================================================

variable "enable_dev_environments" {
  description = "Enable development environment provisioning"
  type        = bool
  default     = false
}

variable "dev_node_machine_type" {
  description = "Machine type for development GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "dev_max_nodes" {
  description = "Maximum nodes for development environment"
  type        = number
  default     = 3
  
  validation {
    condition     = var.dev_max_nodes >= 1 && var.dev_max_nodes <= 10
    error_message = "Development max nodes must be between 1 and 10."
  }
}

# =============================================================================
# Resource Tagging Configuration
# =============================================================================

variable "additional_labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for k, v in var.additional_labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))
    ])
    error_message = "Label keys and values must follow GCP naming conventions."
  }
}

variable "cost_center" {
  description = "Cost center for resource billing"
  type        = string
  default     = "engineering"
}

variable "owner_team" {
  description = "Team responsible for the resources"
  type        = string
  default     = "platform-engineering"
}

variable "business_unit" {
  description = "Business unit for resource allocation"
  type        = string
  default     = "technology"
}

# =============================================================================
# Feature Flags
# =============================================================================

variable "enable_experimental_features" {
  description = "Enable experimental features (use with caution)"
  type        = bool
  default     = false
}

variable "enable_debug_mode" {
  description = "Enable debug mode for troubleshooting"
  type        = bool
  default     = false
}

variable "enable_maintenance_mode" {
  description = "Enable maintenance mode"
  type        = bool
  default     = false
}

# =============================================================================
# Integration Configuration
# =============================================================================

variable "enable_istio_service_mesh" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}

variable "enable_knative_serving" {
  description = "Enable Knative for serverless workloads"
  type        = bool
  default     = false
}

variable "enable_anthos_config_management" {
  description = "Enable Anthos Config Management"
  type        = bool
  default     = false
}

# =============================================================================
# Performance Configuration
# =============================================================================

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable Horizontal Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaling_profiles" {
  description = "Enable cluster autoscaling profiles for optimization"
  type        = bool
  default     = true
}

variable "node_pool_surge_settings" {
  description = "Node pool surge settings for rolling updates"
  type = object({
    max_surge       = number
    max_unavailable = number
  })
  default = {
    max_surge       = 1
    max_unavailable = 0
  }
  
  validation {
    condition     = var.node_pool_surge_settings.max_surge >= 0 && var.node_pool_surge_settings.max_unavailable >= 0
    error_message = "Surge settings must be non-negative."
  }
}