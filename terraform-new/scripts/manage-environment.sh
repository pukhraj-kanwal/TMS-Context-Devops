#!/bin/bash

# CargoLynx TMS - Environment Management Script
# Handles environment lifecycle operations: start, stop, status, cleanup

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_debug() { [[ ${DEBUG:-false} == "true" ]] && echo -e "${PURPLE}[DEBUG]${NC} $1" || true; }

# Help function
show_help() {
    cat << EOF
CargoLynx TMS Environment Management

USAGE:
    $0 <command> <environment> [options]

COMMANDS:
    start       Start environment infrastructure
    stop        Stop environment infrastructure (dev only)
    status      Show environment status and resources
    cleanup     Clean up environment resources
    costs       Show current and projected costs
    logs        Fetch and display environment logs
    backup      Create environment backup
    restore     Restore environment from backup
    scale       Scale environment resources

ENVIRONMENTS:
    local       Local development (FREE TIER optimized)
    development Development environment (cost-balanced)
    staging     Staging environment (production-like)
    uat         User acceptance testing
    production  Production environment (high availability)

OPTIONS:
    --dry-run   Show what would be done without executing
    --force     Skip confirmation prompts
    --debug     Enable debug logging
    --region    Override default region
    --project   Override default GCP project

EXAMPLES:
    $0 status local
    $0 start development --dry-run
    $0 stop development --force
    $0 costs production
    $0 scale development --nodes=5
    $0 backup production --force

ENVIRONMENT VARIABLES:
    GOOGLE_CLOUD_PROJECT    GCP project ID
    GOOGLE_APPLICATION_CREDENTIALS    Service account key file
    TF_VAR_*               Terraform variables
    DEBUG                  Enable debug mode (true/false)

EOF
}

# Validation functions
validate_environment() {
    local env="$1"
    local valid_envs=("local" "development" "staging" "uat" "production")
    
    if [[ ! " ${valid_envs[@]} " =~ " ${env} " ]]; then
        log_error "Invalid environment: $env"
        log_info "Valid environments: ${valid_envs[*]}"
        exit 1
    fi
    
    if [[ ! -d "$ENVIRONMENTS_DIR/$env" ]]; then
        log_error "Environment directory not found: $ENVIRONMENTS_DIR/$env"
        exit 1
    fi
}

validate_prerequisites() {
    local missing_tools=()
    
    command -v terraform >/dev/null 2>&1 || missing_tools+=("terraform")
    command -v gcloud >/dev/null 2>&1 || missing_tools+=("gcloud")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install missing tools and try again"
        exit 1
    fi
}

validate_gcp_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 | grep -q "@"; then
        log_error "No active GCP authentication found"
        log_info "Run: gcloud auth login"
        exit 1
    fi
    
    if [[ -z "${GOOGLE_CLOUD_PROJECT:-}" ]]; then
        log_error "GOOGLE_CLOUD_PROJECT environment variable not set"
        log_info "Run: export GOOGLE_CLOUD_PROJECT=your-project-id"
        exit 1
    fi
}

# Environment status functions
get_terraform_state() {
    local env="$1"
    local env_dir="$ENVIRONMENTS_DIR/$env"
    
    cd "$env_dir"
    
    if [[ ! -f "terraform.tfstate" && ! -f ".terraform/terraform.tfstate" ]]; then
        echo "not_deployed"
        return
    fi
    
    local state_file
    if [[ -f "terraform.tfstate" ]]; then
        state_file="terraform.tfstate"
    else
        state_file=".terraform/terraform.tfstate"
    fi
    
    if terraform show -json "$state_file" >/dev/null 2>&1; then
        echo "deployed"
    else
        echo "corrupted"
    fi
}

get_gke_status() {
    local env="$1"
    local cluster_name="cargolynx-tms-$env"
    local region="${REGION:-us-central1}"
    
    if gcloud container clusters describe "$cluster_name" \
        --region="$region" \
        --project="$GOOGLE_CLOUD_PROJECT" \
        --format="value(status)" 2>/dev/null; then
        return 0
    else
        echo "not_found"
        return 1
    fi
}

get_database_status() {
    local env="$1"
    local instance_name="cargolynx-tms-$env"
    
    if gcloud sql instances describe "$instance_name" \
        --project="$GOOGLE_CLOUD_PROJECT" \
        --format="value(state)" 2>/dev/null; then
        return 0
    else
        echo "not_found"
        return 1
    fi
}

# Environment operations
start_environment() {
    local env="$1"
    local dry_run="${DRY_RUN:-false}"
    
    log_info "Starting environment: $env"
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
    fi
    
    # Check if already running
    local tf_state=$(get_terraform_state "$env")
    if [[ "$tf_state" == "deployed" ]]; then
        log_warn "Environment $env appears to be already deployed"
        
        # Check specific services
        local gke_status=$(get_gke_status "$env" || echo "stopped")
        local db_status=$(get_database_status "$env" || echo "stopped")
        
        if [[ "$gke_status" == "RUNNING" && "$db_status" == "RUNNABLE" ]]; then
            log_success "Environment $env is already running"
            return 0
        fi
    fi
    
    # Start infrastructure
    if [[ "$dry_run" != "true" ]]; then
        log_info "Calling deployment script..."
        "$SCRIPT_DIR/deploy.sh" "$env" --auto-approve
    else
        log_info "Would call: $SCRIPT_DIR/deploy.sh $env --auto-approve"
    fi
    
    # Verify startup
    if [[ "$dry_run" != "true" ]]; then
        log_info "Verifying environment startup..."
        sleep 30
        
        local gke_status=$(get_gke_status "$env")
        local db_status=$(get_database_status "$env")
        
        if [[ "$gke_status" == "RUNNING" && "$db_status" == "RUNNABLE" ]]; then
            log_success "Environment $env started successfully"
        else
            log_warn "Environment $env may not be fully ready (GKE: $gke_status, DB: $db_status)"
        fi
    fi
}

stop_environment() {
    local env="$1"
    local dry_run="${DRY_RUN:-false}"
    local force="${FORCE:-false}"
    
    # Only allow stopping development environments
    if [[ "$env" == "production" || "$env" == "staging" ]]; then
        log_error "Cannot stop production or staging environments for safety"
        log_info "Use 'cleanup' command with --force if you really need to destroy"
        exit 1
    fi
    
    log_info "Stopping environment: $env"
    
    if [[ "$force" != "true" && "$dry_run" != "true" ]]; then
        echo -n "Are you sure you want to stop environment '$env'? [y/N]: "
        read -r confirmation
        if [[ ! "$confirmation" =~ ^[Yy] ]]; then
            log_info "Operation cancelled"
            exit 0
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        log_info "Would stop GKE node pools for environment: $env"
        return 0
    fi
    
    # For development environments, we can stop node pools to save costs
    local cluster_name="cargolynx-tms-$env"
    local region="${REGION:-us-central1}"
    
    log_info "Stopping GKE node pools..."
    if gcloud container clusters resize "$cluster_name" \
        --region="$region" \
        --num-nodes=0 \
        --node-pool=primary-pool \
        --project="$GOOGLE_CLOUD_PROJECT" \
        --quiet 2>/dev/null; then
        log_success "GKE node pools stopped"
    else
        log_warn "Failed to stop GKE node pools (may not exist)"
    fi
    
    log_success "Environment $env stopped (infrastructure preserved)"
}

show_environment_status() {
    local env="$1"
    
    log_info "Environment Status: $env"
    echo "----------------------------------------"
    
    # Terraform state
    local tf_state=$(get_terraform_state "$env")
    echo -e "Terraform State: ${tf_state}"
    
    # GKE cluster
    local gke_status=$(get_gke_status "$env" 2>/dev/null || echo "not_found")
    echo -e "GKE Cluster: ${gke_status}"
    
    if [[ "$gke_status" == "RUNNING" ]]; then
        local cluster_name="cargolynx-tms-$env"
        local region="${REGION:-us-central1}"
        
        echo -n "  Nodes: "
        gcloud container clusters describe "$cluster_name" \
            --region="$region" \
            --project="$GOOGLE_CLOUD_PROJECT" \
            --format="value(currentNodeCount)" 2>/dev/null || echo "unknown"
    fi
    
    # Database
    local db_status=$(get_database_status "$env" 2>/dev/null || echo "not_found")
    echo -e "Database: ${db_status}"
    
    # Storage buckets
    echo -n "Storage Buckets: "
    local bucket_count=$(gsutil ls -p "$GOOGLE_CLOUD_PROJECT" 2>/dev/null | grep -c "cargolynx-tms-$env" || echo "0")
    echo "$bucket_count found"
    
    # Load balancer
    echo -n "Load Balancer: "
    if gcloud compute addresses list --filter="name:cargolynx-tms-$env*" --format="value(name)" --project="$GOOGLE_CLOUD_PROJECT" | grep -q .; then
        echo "configured"
    else
        echo "not_found"
    fi
    
    echo "----------------------------------------"
}

cleanup_environment() {
    local env="$1"
    local dry_run="${DRY_RUN:-false}"
    local force="${FORCE:-false}"
    
    log_warn "DESTRUCTIVE OPERATION: Cleaning up environment: $env"
    
    if [[ "$env" == "production" && "$force" != "true" ]]; then
        log_error "Cannot cleanup production environment without --force flag"
        exit 1
    fi
    
    if [[ "$force" != "true" && "$dry_run" != "true" ]]; then
        echo -e "${RED}WARNING: This will DESTROY all resources in environment '$env'${NC}"
        echo -n "Type 'DELETE' to confirm: "
        read -r confirmation
        if [[ "$confirmation" != "DELETE" ]]; then
            log_info "Operation cancelled"
            exit 0
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_warn "DRY RUN MODE - No resources will be destroyed"
        log_info "Would destroy all Terraform resources for environment: $env"
        return 0
    fi
    
    local env_dir="$ENVIRONMENTS_DIR/$env"
    cd "$env_dir"
    
    log_info "Destroying Terraform resources..."
    if terraform destroy -auto-approve; then
        log_success "Terraform resources destroyed"
    else
        log_error "Failed to destroy some Terraform resources"
        log_info "You may need to manually clean up remaining resources"
    fi
    
    # Clean up any orphaned resources
    log_info "Checking for orphaned resources..."
    
    # Clean up any remaining storage buckets
    local buckets=$(gsutil ls -p "$GOOGLE_CLOUD_PROJECT" 2>/dev/null | grep "cargolynx-tms-$env" || true)
    if [[ -n "$buckets" ]]; then
        log_warn "Found orphaned storage buckets, removing..."
        echo "$buckets" | while read -r bucket; do
            gsutil rm -r "$bucket" 2>/dev/null || log_warn "Failed to remove bucket: $bucket"
        done
    fi
    
    log_success "Environment $env cleanup completed"
}

show_environment_costs() {
    local env="$1"
    
    log_info "Cost Analysis for Environment: $env"
    echo "----------------------------------------"
    
    # Get billing data if available
    if command -v gcloud >/dev/null 2>&1; then
        log_info "Fetching current month costs..."
        
        local current_month=$(date +%Y-%m)
        local project="$GOOGLE_CLOUD_PROJECT"
        
        # Note: This requires billing export to be configured
        echo "Current month estimated costs:"
        gcloud billing budget list --billing-account="$(gcloud billing accounts list --format='value(name)' | head -n1)" \
            --format="table(displayName,amount.specifiedAmount.currencyCode,amount.specifiedAmount.units)" 2>/dev/null || \
            echo "  Billing data not available (configure billing export for detailed costs)"
    fi
    
    # Show resource estimates based on environment
    echo ""
    echo "Estimated monthly costs by environment type:"
    case "$env" in
        "local")
            echo "  • Compute Engine (e2-micro): FREE TIER"
            echo "  • Cloud SQL (db-f1-micro): FREE TIER"
            echo "  • Storage (Standard): $5-10/month"
            echo "  • Networking: $2-5/month"
            echo "  TOTAL ESTIMATE: $7-15/month"
            ;;
        "development")
            echo "  • GKE Cluster: $20-30/month"
            echo "  • Cloud SQL (db-custom-1-3840): $25-35/month"
            echo "  • Storage: $10-20/month"
            echo "  • Networking: $5-10/month"
            echo "  TOTAL ESTIMATE: $60-95/month"
            ;;
        "production")
            echo "  • GKE Cluster (regional): $150-200/month"
            echo "  • Cloud SQL (HA): $200-300/month"
            echo "  • Storage: $50-100/month"
            echo "  • Load Balancer: $20-30/month"
            echo "  • Monitoring: $20-40/month"
            echo "  TOTAL ESTIMATE: $440-670/month"
            ;;
    esac
    
    echo "----------------------------------------"
}

# Main function
main() {
    # Parse arguments
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
    esac
    
    if [[ $# -lt 1 ]]; then
        log_error "Environment required"
        show_help
        exit 1
    fi
    
    local environment="$1"
    shift
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            --force)
                export FORCE=true
                shift
                ;;
            --debug)
                export DEBUG=true
                shift
                ;;
            --region)
                export REGION="$2"
                shift 2
                ;;
            --project)
                export GOOGLE_CLOUD_PROJECT="$2"
                shift 2
                ;;
            --nodes)
                export NODE_COUNT="${2}"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validation
    validate_environment "$environment"
    validate_prerequisites
    validate_gcp_auth
    
    # Execute command
    case "$command" in
        "start")
            start_environment "$environment"
            ;;
        "stop")
            stop_environment "$environment"
            ;;
        "status")
            show_environment_status "$environment"
            ;;
        "cleanup")
            cleanup_environment "$environment"
            ;;
        "costs")
            show_environment_costs "$environment"
            ;;
        "logs")
            log_error "Logs command not yet implemented"
            exit 1
            ;;
        "backup")
            log_error "Backup command not yet implemented"
            exit 1
            ;;
        "restore")
            log_error "Restore command not yet implemented"
            exit 1
            ;;
        "scale")
            log_error "Scale command not yet implemented"
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"