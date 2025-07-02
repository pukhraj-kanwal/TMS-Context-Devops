# =============================================================================
# CargoLynx TMS - Networking Module Outputs
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

# =============================================================================
# VPC Network Outputs
# =============================================================================

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc_network.self_link
}

# =============================================================================
# Subnet Outputs
# =============================================================================

output "gke_subnet_id" {
  description = "The ID of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "gke_subnet_name" {
  description = "The name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_self_link" {
  description = "The self-link of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "database_subnet_id" {
  description = "The ID of the database subnet"
  value       = google_compute_subnetwork.database_subnet.id
}

output "database_subnet_name" {
  description = "The name of the database subnet"
  value       = google_compute_subnetwork.database_subnet.name
}

# =============================================================================
# Secondary IP Range Outputs
# =============================================================================

output "gke_pods_secondary_range_name" {
  description = "The name of the secondary IP range for GKE pods"
  value       = "${var.environment}-gke-pods"
}

output "gke_services_secondary_range_name" {
  description = "The name of the secondary IP range for GKE services"
  value       = "${var.environment}-gke-services"
}

# =============================================================================
# NAT Gateway Outputs
# =============================================================================

output "nat_gateway_ip" {
  description = "The external IP address of the NAT gateway"
  value       = google_compute_address.nat_gateway_ip.address
}

output "cloud_router_name" {
  description = "The name of the cloud router"
  value       = google_compute_router.cloud_router.name
}

# =============================================================================
# Private Service Connection Outputs
# =============================================================================

output "private_service_range_name" {
  description = "The name of the private service connection IP range"
  value       = google_compute_global_address.private_service_range.name
}

output "private_vpc_connection_service" {
  description = "The service networking connection for private VPC"
  value       = google_service_networking_connection.private_vpc_connection.service
}

# =============================================================================
# Firewall Rules Outputs
# =============================================================================

output "firewall_rules" {
  description = "List of created firewall rules"
  value = {
    allow_internal        = google_compute_firewall.allow_internal.name
    allow_ssh_iap        = google_compute_firewall.allow_ssh_iap.name
    allow_health_checks  = google_compute_firewall.allow_health_checks.name
    allow_https_ingress  = google_compute_firewall.allow_https_ingress.name
    deny_all_ingress     = google_compute_firewall.deny_all_ingress.name
  }
}

# =============================================================================
# Network Summary
# =============================================================================

output "network_summary" {
  description = "Summary of networking configuration"
  value = {
    vpc_network_name = google_compute_network.vpc_network.name
    region          = var.region
    subnets = {
      gke_subnet = {
        name       = google_compute_subnetwork.gke_subnet.name
        cidr       = var.gke_subnet_cidr
        pods_cidr  = var.gke_pods_cidr
        svc_cidr   = var.gke_services_cidr
      }
      database_subnet = {
        name = google_compute_subnetwork.database_subnet.name
        cidr = var.database_subnet_cidr
      }
    }
    nat_gateway = {
      external_ip = google_compute_address.nat_gateway_ip.address
      router_name = google_compute_router.cloud_router.name
    }
  }
}