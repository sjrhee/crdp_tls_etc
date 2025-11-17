#!/bin/bash

###############################################################################
# CRDP TLS Deployment Script
# Description: Helm chart deployment script for CRDP with TLS configuration
# Usage: ./deploy-crdp-tls.sh [install|upgrade|uninstall]
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
RELEASE_NAME="crdp-tls"
CHART_PATH="."
NAMESPACE="default"

# Required files
CERT_FILE="Certificate.pem"
KEY_FILE="key.pem"
VALUES_TEMPLATE="values.yaml"

###############################################################################
# Functions
###############################################################################

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi
    
    # Check kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if certificate files exist
    if [[ ! -f "$CERT_FILE" ]]; then
        print_error "Certificate file not found: $CERT_FILE"
        exit 1
    fi
    
    if [[ ! -f "$KEY_FILE" ]]; then
        print_error "Key file not found: $KEY_FILE"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

generate_values_yaml() {
    print_info "Generating values.yaml with base64 encoded certificates..."
    
    # Generate base64 encoded values using Python
    python3 << 'EOFPYTHON'
import base64

# Read certificates
with open('Certificate.pem', 'rb') as f:
    cert_b64 = base64.b64encode(f.read()).decode('ascii')
    
with open('key.pem', 'rb') as f:
    key_b64 = base64.b64encode(f.read()).decode('ascii')

# Create values.yaml content
values_content = f"""label: crdp-tls

deployment:

  name: crdp-tls-deployment
  crdpContainername: crdp-tls-container
  crdpimage: thalesciphertrust/ciphertrust-restful-data-protection:latest
  replicas: 2
 
env:
  serverMode: tls-cert-opt
  kms: 192.168.0.230 # IP address or hostname of CipherTrust Manager 
  regToken: s4NglgTjxtvzSGs0cG1mdrZXqMJ5LL0Tj9WvgPSqg8OoTeDdoLRbJUFR0FvIiGAP

service:
  name: crdp-tls-service
  type: NodePort
  nodePort: 32182 # This value can be any number between 30000-32767
  port: 8090
  probesPort: 8080
  nodePortForProbes: 32180 # This value can be any number between 30000-32767
configuration:
  servercrt: {cert_b64}
  serverkey: {key_b64}
"""

with open('values.yaml', 'w') as f:
    f.write(values_content)
    
print(f"Certificate length: {len(cert_b64)} bytes")
print(f"Key length: {len(key_b64)} bytes")
EOFPYTHON

    if [[ $? -eq 0 ]]; then
        print_success "values.yaml generated successfully"
    else
        print_error "Failed to generate values.yaml"
        exit 1
    fi
}

validate_helm_chart() {
    print_info "Validating Helm chart..."
    
    if helm lint "$CHART_PATH" &> /dev/null; then
        print_success "Helm chart validation passed"
    else
        print_warning "Helm chart validation has warnings"
        helm lint "$CHART_PATH"
    fi
    
    print_info "Running dry-run..."
    if helm install "$RELEASE_NAME" "$CHART_PATH" --dry-run --debug > /tmp/helm-dry-run.log 2>&1; then
        print_success "Dry-run completed successfully"
    else
        print_error "Dry-run failed. Check /tmp/helm-dry-run.log for details"
        tail -50 /tmp/helm-dry-run.log
        exit 1
    fi
}

install_chart() {
    print_info "Installing Helm chart..."
    
    # Check if release already exists
    if helm list -n "$NAMESPACE" | grep -q "^$RELEASE_NAME"; then
        print_warning "Release '$RELEASE_NAME' already exists"
        read -p "Do you want to upgrade it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            upgrade_chart
            return
        else
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    helm install "$RELEASE_NAME" "$CHART_PATH" -n "$NAMESPACE"
    
    if [[ $? -eq 0 ]]; then
        print_success "Helm chart installed successfully"
        show_status
    else
        print_error "Helm chart installation failed"
        exit 1
    fi
}

upgrade_chart() {
    print_info "Upgrading Helm chart..."
    
    helm upgrade "$RELEASE_NAME" "$CHART_PATH" -n "$NAMESPACE"
    
    if [[ $? -eq 0 ]]; then
        print_success "Helm chart upgraded successfully"
        show_status
    else
        print_error "Helm chart upgrade failed"
        exit 1
    fi
}

uninstall_chart() {
    print_info "Uninstalling Helm chart..."
    
    if ! helm list -n "$NAMESPACE" | grep -q "^$RELEASE_NAME"; then
        print_warning "Release '$RELEASE_NAME' not found"
        exit 0
    fi
    
    read -p "Are you sure you want to uninstall '$RELEASE_NAME'? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
    
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
    
    if [[ $? -eq 0 ]]; then
        print_success "Helm chart uninstalled successfully"
    else
        print_error "Helm chart uninstallation failed"
        exit 1
    fi
}

show_status() {
    echo ""
    print_info "Deployment Status:"
    echo "===================="
    
    echo ""
    echo "Release Information:"
    helm list -n "$NAMESPACE" | grep "$RELEASE_NAME"
    
    echo ""
    echo "Pods:"
    kubectl get pods -l app=crdp-tls -n "$NAMESPACE"
    
    echo ""
    echo "Services:"
    kubectl get svc -l app=crdp-tls -n "$NAMESPACE"
    
    echo ""
    echo "Secrets:"
    kubectl get secret "${RELEASE_NAME}-tls" -n "$NAMESPACE" 2>/dev/null || echo "Secret not found"
    
    echo ""
    print_info "To check pod logs, run:"
    echo "  kubectl logs -l app=crdp-tls -n $NAMESPACE"
    
    echo ""
    print_info "To check pod environment variables, run:"
    echo "  kubectl describe pod -l app=crdp-tls -n $NAMESPACE | grep -A 10 'Environment:'"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    install     - Install CRDP with TLS configuration
    upgrade     - Upgrade existing CRDP deployment
    uninstall   - Uninstall CRDP deployment
    status      - Show deployment status
    validate    - Validate Helm chart only (dry-run)
    help        - Show this help message

Examples:
    $0 install
    $0 upgrade
    $0 uninstall
    $0 status

Configuration:
    Release Name: $RELEASE_NAME
    Namespace: $NAMESPACE
    Chart Path: $CHART_PATH
    Certificate: $CERT_FILE
    Key: $KEY_FILE

EOF
}

###############################################################################
# Main Script
###############################################################################

main() {
    local command=${1:-""}
    
    case "$command" in
        install)
            check_prerequisites
            generate_values_yaml
            validate_helm_chart
            install_chart
            ;;
        upgrade)
            check_prerequisites
            generate_values_yaml
            validate_helm_chart
            upgrade_chart
            ;;
        uninstall)
            uninstall_chart
            ;;
        status)
            show_status
            ;;
        validate)
            check_prerequisites
            generate_values_yaml
            validate_helm_chart
            print_success "Validation completed successfully"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Invalid command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
