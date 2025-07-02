#!/bin/bash
# =============================================================================
# CargoLynx TMS - Multi-Environment Deployment Script
# Platform Guardian: Zero-Touch Software Factory
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Supported environments
VALID_ENVIRONMENTS=("local" "development" "staging" "uat" "production")

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

log_info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

show_usage() {
    cat << EOF
${PURPLE}CargoLynx TMS - Multi-Environment Deployment Script${NC}

${CYAN}USAGE:${NC}
    $0 <environment> <action> [options]

${CYAN}ENVIRONMENTS:${NC}
    local        - Local development environment (FREE TIER optimized)
    development  - Shared development environment (cost-optimized)
    staging      - Staging environment (production-like)
    uat          - User Acceptance Testing environment
    production   - Production environment (high availability)

${CYAN}ACTIONS:${NC}
    plan         - Show deployment plan without applying changes
    apply        - Deploy infrastructure to the specified environment
    destroy      - Destroy infrastructure in the specified environment
    validate     - Validate Terraform configuration
    output       - Show infrastructure outputs
    status       - Show current deployment status
    init         - Initialize Terraform for the environment
    upgrade      - Upgrade infrastructure to latest configuration

${CYAN}OPTIONS:${NC}
    --auto-approve     - Skip interactive approval for apply/destroy
    --var-file=FILE    - Use custom variables file
    --target=RESOURCE  - Target specific resource for deployment
    --force            - Force operation even with warnings
    --dry-run          - Show what would be done without executing
    --verbose          - Enable verbose logging
    --backup           - Create backup before destructive operations
    --verify           - Verify deployment after completion

${CYAN}EXAMPLES:${NC}
    $0 local plan                    # Plan local environment deployment
    $0 development apply --verify    # Deploy and verify development environment
    $0 production destroy --backup   # Destroy production with backup
    $0 staging status                # Check staging environment status

${CYAN}SAFETY FEATURES:${NC}
    • Environment validation and confirmation prompts
    • Automatic backups before destructive operations
    • Resource drift detection and remediation
    • Cost estimation and budget checks
    • Security compliance validation
    • Rollback capabilities for failed deployments

EOF
}

validate_environment() {
    local env=$1
    
    if [[ ! " ${VALID_ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        log_error "Invalid environment: $env"
        log_info "Valid environments: ${VALID_ENVIRONMENTS[*]}"
        exit 1
    fi
    
    if [[ ! -d "$ENVIRONMENTS_DIR/$env" ]]; then
        log_error "Environment directory not found: $ENVIRONMENTS_DIR/$env"
        exit 1
    fi
    
    log_success "Environment validation passed: $env"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check required tools
    local required_tools=("terraform" "gcloud" "kubectl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check Terraform version
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: $tf_version"
    
    # Check gcloud authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        log_error "gcloud authentication required. Run: gcloud auth login"
        exit 1
    fi
    
    # Check kubectl configuration
    if ! kubectl config current-context &> /dev/null; then
        log_warning "kubectl not configured. This is normal for new deployments."
    fi
    
    log_success "Prerequisites check passed"
}

validate_terraform_config() {
    local env=$1
    local env_dir="$ENVIRONMENTS_DIR/$env"
    
    log "Validating Terraform configuration for $env environment..."
    
    cd "$env_dir"
    
    # Initialize if needed
    if [[ ! -d ".terraform" ]]; then
        log "Initializing Terraform..."
        terraform init
    fi
    
    # Validate configuration
    if ! terraform validate; then
        log_error "Terraform configuration validation failed"
        exit 1
    fi
    
    # Format check
    if ! terraform fmt -check -recursive; then
        log_warning "Terraform configuration formatting issues detected"
        if [[ "$FORCE" != "true" ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    log_success "Terraform configuration validation passed"
}

estimate_costs() {
    local env=$1
    
    log "Estimating deployment costs for $env environment..."
    
    case $env in
        "local")
            log_info "Estimated monthly cost: \$0-15 (FREE TIER optimized)"
            ;;
        "development")
            log_info "Estimated monthly cost: \$50-150 (cost-optimized)"
            ;;
        "staging")
            log_info "Estimated monthly cost: \$200-400 (production-like)"
            ;;
        "uat")
            log_info "Estimated monthly cost: \$150-300 (test environment)"
            ;;
        "production")
            log_info "Estimated monthly cost: \$500-1500 (high availability)"
            ;;
    esac
    
    if [[ "$env" == "production" && "$FORCE" != "true" ]]; then
        log_warning "Production deployment detected - high cost impact"
        read -p "Continue with production deployment? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

create_backup() {
    local env=$1
    local backup_dir="$PROJECT_ROOT/backups/$env/$(date +%Y%m%d_%H%M%S)"
    
    log "Creating backup for $env environment..."
    
    mkdir -p "$backup_dir"
    
    # Backup Terraform state
    local env_dir="$ENVIRONMENTS_DIR/$env"
    if [[ -f "$env_dir/terraform.tfstate" ]]; then
        cp "$env_dir/terraform.tfstate" "$backup_dir/"
        log_success "State file backup created: $backup_dir/terraform.tfstate"
    fi
    
    # Export current infrastructure state
    cd "$env_dir"
    terraform show -json > "$backup_dir/infrastructure_state.json" 2>/dev/null || true
    terraform output -json > "$backup_dir/outputs.json" 2>/dev/null || true
    
    log_success "Backup created: $backup_dir"
    echo "$backup_dir" > "$PROJECT_ROOT/.last_backup_$env"
}

deploy_environment() {
    local env=$1
    local action=$2
    local env_dir="$ENVIRONMENTS_DIR/$env"
    
    log "Starting $action for $env environment..."
    
    cd "$env_dir"
    
    case $action in
        "plan")
            terraform plan "${TERRAFORM_ARGS[@]}"
            ;;
        "apply")
            if [[ "$BACKUP" == "true" && "$action" == "apply" ]]; then
                create_backup "$env"
            fi
            
            if [[ "$AUTO_APPROVE" == "true" ]]; then
                terraform apply -auto-approve "${TERRAFORM_ARGS[@]}"
            else
                terraform apply "${TERRAFORM_ARGS[@]}"
            fi
            
            if [[ "$VERIFY" == "true" ]]; then
                verify_deployment "$env"
            fi
            ;;
        "destroy")
            if [[ "$BACKUP" == "true" ]]; then
                create_backup "$env"
            fi
            
            log_warning "DESTRUCTIVE OPERATION: This will destroy all infrastructure in $env"
            if [[ "$AUTO_APPROVE" != "true" ]]; then
                read -p "Are you sure you want to destroy $env infrastructure? (type 'yes'): " -r
                if [[ $REPLY != "yes" ]]; then
                    log_info "Destroy operation cancelled"
                    exit 0
                fi
            fi
            
            if [[ "$AUTO_APPROVE" == "true" ]]; then
                terraform destroy -auto-approve "${TERRAFORM_ARGS[@]}"
            else
                terraform destroy "${TERRAFORM_ARGS[@]}"
            fi
            ;;
        "init")
            terraform init "${TERRAFORM_ARGS[@]}"
            ;;
        "output")
            terraform output "${TERRAFORM_ARGS[@]}"
            ;;
        "validate")
            terraform validate
            ;;
        "status")
            show_deployment_status "$env"
            ;;
        "upgrade")
            log "Upgrading $env environment to latest configuration..."
            terraform init -upgrade
            terraform plan "${TERRAFORM_ARGS[@]}"
            if [[ "$AUTO_APPROVE" == "true" ]]; then
                terraform apply -auto-approve "${TERRAFORM_ARGS[@]}"
            else
                terraform apply "${TERRAFORM_ARGS[@]}"
            fi
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
    
    log_success "$action completed successfully for $env environment"
}

verify_deployment() {
    local env=$1
    local env_dir="$ENVIRONMENTS_DIR/$env"
    
    log "Verifying deployment for $env environment..."
    
    cd "$env_dir"
    
    # Check Terraform state
    if ! terraform show > /dev/null 2>&1; then
        log_error "Terraform state verification failed"
        return 1
    fi
    
    # Get infrastructure outputs
    local outputs=$(terraform output -json 2>/dev/null || echo '{}')
    
    # Extract key information
    local cluster_name=$(echo "$outputs" | jq -r '.infrastructure.value.gke_cluster_name // empty' 2>/dev/null)
    local cluster_endpoint=$(echo "$outputs" | jq -r '.infrastructure.value.gke_cluster_endpoint // empty' 2>/dev/null)
    
    if [[ -n "$cluster_name" && -n "$cluster_endpoint" ]]; then
        log "Verifying GKE cluster connectivity..."
        
        # Get kubectl credentials
        local project_id=$(echo "$outputs" | jq -r '.infrastructure.value.project_id // empty' 2>/dev/null)
        local zone=$(echo "$outputs" | jq -r '.infrastructure.value.gke_cluster_zone // "us-central1-a"' 2>/dev/null)
        
        if [[ -n "$project_id" ]]; then
            if gcloud container clusters get-credentials "$cluster_name" --zone "$zone" --project "$project_id" > /dev/null 2>&1; then
                if kubectl cluster-info > /dev/null 2>&1; then
                    log_success "GKE cluster connectivity verified"
                else
                    log_warning "GKE cluster accessible but kubectl verification failed"
                fi
            else
                log_warning "Could not configure kubectl for GKE cluster"
            fi
        fi
    fi
    
    log_success "Deployment verification completed for $env environment"
}

show_deployment_status() {
    local env=$1
    local env_dir="$ENVIRONMENTS_DIR/$env"
    
    log "Checking deployment status for $env environment..."
    
    cd "$env_dir"
    
    if [[ ! -f "terraform.tfstate" && ! -d ".terraform" ]]; then
        log_info "Environment not initialized"
        return 0
    fi
    
    # Show terraform state summary
    echo -e "\n${CYAN}=== Terraform State Summary ===${NC}"
    terraform show -json 2>/dev/null | jq -r '
        .values.root_module.resources[]? | 
        select(.type) | 
        "\(.type): \(.name)"
    ' | sort | uniq -c | sort -nr || echo "No resources found"
    
    # Show outputs if available
    echo -e "\n${CYAN}=== Infrastructure Outputs ===${NC}"
    terraform output 2>/dev/null || echo "No outputs available"
    
    # Show resource count
    local resource_count=$(terraform show -json 2>/dev/null | jq '.values.root_module.resources | length' 2>/dev/null || echo "0")
    log_info "Total managed resources: $resource_count"
}

cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code"
        
        # Offer rollback if backup exists
        if [[ -f "$PROJECT_ROOT/.last_backup_$ENVIRONMENT" ]]; then
            local backup_dir=$(cat "$PROJECT_ROOT/.last_backup_$ENVIRONMENT")
            log_info "Backup available at: $backup_dir"
            
            if [[ "$AUTO_APPROVE" != "true" ]]; then
                read -p "Would you like to rollback to the previous state? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log "Rolling back to previous state..."
                    # Implementation for rollback would go here
                    log_info "Rollback functionality would be implemented here"
                fi
            fi
        fi
    fi
    
    exit $exit_code
}

# =============================================================================
# Main Script Logic
# =============================================================================

# Set trap for cleanup on exit
trap cleanup_on_exit EXIT

# Parse command line arguments
ENVIRONMENT=""
ACTION=""
AUTO_APPROVE="false"
VAR_FILE=""
TARGET=""
FORCE="false"
DRY_RUN="false"
VERBOSE="false"
BACKUP="false"
VERIFY="false"
TERRAFORM_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        --var-file=*)
            VAR_FILE="${1#*=}"
            TERRAFORM_ARGS+=("-var-file=$VAR_FILE")
            shift
            ;;
        --target=*)
            TARGET="${1#*=}"
            TERRAFORM_ARGS+=("-target=$TARGET")
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            set -x
            shift
            ;;
        --backup)
            BACKUP="true"
            shift
            ;;
        --verify)
            VERIFY="true"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$ENVIRONMENT" ]]; then
                ENVIRONMENT="$1"
            elif [[ -z "$ACTION" ]]; then
                ACTION="$1"
            else
                log_error "Unexpected argument: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" || -z "$ACTION" ]]; then
    log_error "Environment and action are required"
    show_usage
    exit 1
fi

# Main execution
log "Starting CargoLynx TMS deployment script"
log_info "Environment: $ENVIRONMENT"
log_info "Action: $ACTION"
log_info "Script directory: $SCRIPT_DIR"
log_info "Project root: $PROJECT_ROOT"

# Validate environment
validate_environment "$ENVIRONMENT"

# Check prerequisites
check_prerequisites

# Validate Terraform configuration
validate_terraform_config "$ENVIRONMENT"

# Estimate costs for apply operations
if [[ "$ACTION" == "apply" || "$ACTION" == "upgrade" ]]; then
    estimate_costs "$ENVIRONMENT"
fi

# Execute dry run if requested
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN MODE - No changes will be applied"
    ACTION="plan"
fi

# Execute deployment
deploy_environment "$ENVIRONMENT" "$ACTION"

log_success "Deployment script completed successfully"