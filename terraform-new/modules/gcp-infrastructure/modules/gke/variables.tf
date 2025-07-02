# =============================================================================
# CargoLynx TMS - GKE Module Variables
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (local, development, staging, uat, production)"
  type        = string
}

variable "vpc_network_id" {
  description = "The ID of the VPC network"
  type        = string
}

variable "vpc_network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "gke_subnet_id" {
  description = "The ID of the GKE subnet"
  type        = string
}

variable "gke_subnet_name" {
  description = "The name of the GKE subnet"
  type        = string
}

variable "gke_pods_secondary_range_name" {
  description = "The name of the secondary IP range for GKE pods"
  type        = string
}

variable "gke_services_secondary_range_name" {
  description = "The name of the secondary IP range for GKE services"
  type        = string
}

variable "gke_service_account_email" {
  description = "Email address of the GKE service account"
  type        = string
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode for simplified management"
  type        = bool
  default     = false
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}

variable "gke_node_disk_size" {
  description = "Disk size for GKE nodes in GB"
  type        = number
}

variable "gke_node_count" {
  description = "Initial number of nodes in the GKE node pool"
  type        = number
}

variable "gke_min_nodes" {
  description = "Minimum number of nodes in the GKE node pool"
  type        = number
}

variable "gke_max_nodes" {
  description = "Maximum number of nodes in the GKE node pool"
  type        = number
}

variable "preemptible_node_pool" {
  description = "Enable preemptible node pool for cost savings"
  type        = bool
}

variable "spot_node_pool" {
  description = "Enable spot instance node pool for cost savings"
  type        = bool
}

variable "gke_node_taints" {
  description = "List of taints to apply to GKE nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "apis_enabled" {
  description = "Dependency marker for APIs being enabled"
  type        = any
  default     = null
}