# =============================================================================
# CargoLynx TMS - Networking Module
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
# VPC Network
# =============================================================================

resource "google_compute_network" "vpc_network" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
  description            = "VPC network for ${var.environment} environment"

  depends_on = [
    var.apis_enabled
  ]
}

# =============================================================================
# Subnets
# =============================================================================

# GKE Subnet with secondary ranges for pods and services
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "${var.environment}-gke-subnet"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Subnet for GKE cluster in ${var.environment} environment"

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "${var.environment}-gke-pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "${var.environment}-gke-services"
    ip_cidr_range = var.gke_services_cidr
  }

  # Enable private Google access for accessing GCP services without external IPs
  private_ip_google_access = true

  # Enable flow logs for network monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
}

# Database Subnet for Cloud SQL private networking
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.environment}-database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Subnet for database services in ${var.environment} environment"

  private_ip_google_access = true
}

# =============================================================================
# Cloud Router and NAT Gateway
# =============================================================================

# Cloud Router for NAT gateway
resource "google_compute_router" "cloud_router" {
  name    = "${var.environment}-cloud-router"
  region  = var.region
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

# External IP for NAT gateway
resource "google_compute_address" "nat_gateway_ip" {
  name         = "${var.environment}-nat-gateway-ip"
  address_type = "EXTERNAL"
  region       = var.region
  description  = "External IP for NAT gateway in ${var.environment} environment"
}

# NAT Gateway for outbound internet access from private instances
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.environment}-nat-gateway"
  router                            = google_compute_router.cloud_router.name
  region                           = var.region
  nat_ip_allocate_option           = "MANUAL_ONLY"
  nat_ips                          = [google_compute_address.nat_gateway_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Logging configuration
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# =============================================================================
# Private Service Connection for Cloud SQL
# =============================================================================

# Reserve IP range for private service connection
resource "google_compute_global_address" "private_service_range" {
  name          = "${var.environment}-private-service-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.vpc_network.id
  description   = "IP range for private service connection in ${var.environment} environment"
}

# Create private VPC connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  depends_on = [
    var.apis_enabled
  ]
}

# =============================================================================
# Firewall Rules
# =============================================================================

# Allow internal communication within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc_network.name

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

  direction = "INGRESS"
  priority  = 1000
}

# Allow SSH access for debugging (restricted to IAP)
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.environment}-allow-ssh-iap"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Google's IAP source ranges
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
  direction     = "INGRESS"
  priority      = 1000
}

# Allow health check probes
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.environment}-allow-health-checks"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  # Google Cloud health check source ranges
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["allow-health-checks"]
  direction   = "INGRESS"
  priority    = 1000
}

# Allow HTTPS ingress for web services
resource "google_compute_firewall" "allow_https_ingress" {
  name    = "${var.environment}-allow-https-ingress"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  direction     = "INGRESS"
  priority      = 1000
}

# Deny all other ingress traffic (explicit deny)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.environment}-deny-all-ingress"
  network = google_compute_network.vpc_network.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 65534
}