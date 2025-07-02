# =============================================================================
# CargoLynx TMS - GKE Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_self_link" {
  description = "The self-link of the GKE cluster"
  value       = google_container_cluster.primary.self_link
}

# =============================================================================
# Node Pool Outputs
# =============================================================================

output "node_pool_id" {
  description = "The ID of the GKE node pool"
  value       = google_container_node_pool.primary_nodes.id
}

output "node_pool_name" {
  description = "The name of the GKE node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_pool_instance_group_urls" {
  description = "List of instance group URLs associated with the node pool"
  value       = google_container_node_pool.primary_nodes.instance_group_urls
}

output "node_pool_managed_instance_group_urls" {
  description = "List of managed instance group URLs associated with the node pool"
  value       = google_container_node_pool.primary_nodes.managed_instance_group_urls
}

# =============================================================================
# Cluster Configuration Outputs
# =============================================================================

output "workload_identity_pool" {
  description = "The Workload Identity pool for the cluster"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}

output "master_version" {
  description = "The current master version of the GKE cluster"
  value       = google_container_cluster.primary.master_version
}

output "node_version" {
  description = "The current node version of the GKE cluster"
  value       = google_container_node_pool.primary_nodes.version
}

output "services_ipv4_cidr" {
  description = "The IP address range of the Kubernetes services"
  value       = google_container_cluster.primary.services_ipv4_cidr
}

output "cluster_ipv4_cidr" {
  description = "The IP address range of the Kubernetes cluster"
  value       = google_container_cluster.primary.cluster_ipv4_cidr
}

# =============================================================================
# Connection Information
# =============================================================================

output "kubectl_config" {
  description = "kubectl configuration command"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}

# =============================================================================
# GKE Summary
# =============================================================================

output "gke_summary" {
  description = "Summary of GKE cluster configuration"
  value = {
    environment    = var.environment
    cluster_name   = google_container_cluster.primary.name
    cluster_location = google_container_cluster.primary.location
    node_pool_name = google_container_node_pool.primary_nodes.name
    machine_type   = var.gke_node_machine_type
    node_count = {
      initial = var.gke_node_count
      min     = var.gke_min_nodes
      max     = var.gke_max_nodes
    }
    features = {
      workload_identity = true
      network_policy    = true
      private_cluster   = true
      autopilot        = var.enable_autopilot
      preemptible      = var.preemptible_node_pool
      spot_instances   = var.spot_node_pool
    }
    networking = {
      vpc_network   = var.vpc_network_name
      subnet        = var.gke_subnet_name
      pods_range    = var.gke_pods_secondary_range_name
      services_range = var.gke_services_secondary_range_name
    }
  }
}