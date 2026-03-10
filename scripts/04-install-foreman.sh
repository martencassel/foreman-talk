#!/bin/bash
set -euo pipefail

###############################################
# Logging helpers
###############################################
log()  { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
step() { echo -e "\n\e[36m=== $* ===\e[0m\n"; }

###############################################
# Help screen
###############################################
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --skip-installer       Skip running foreman-installer
  --skip-logs            Skip showing logs after installation
  --realm-provider NAME  Realm provider (default: ad)
  -h, --help             Show this help screen

Examples:
  $0
  $0 --skip-installer
  $0 --realm-provider ad

EOF
    exit 1
}

###############################################
# Defaults
###############################################
SKIP_INSTALLER=false
SKIP_LOGS=false
REALM_PROVIDER="ad"

###############################################
# Argument parsing
###############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-installer)
            SKIP_INSTALLER=true
            shift
            ;;
        --skip-logs)
            SKIP_LOGS=true
            shift
            ;;
        --realm-provider)
            REALM_PROVIDER="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            err "Unknown option: $1"
            usage
            ;;
    esac
done

###############################################
# Step 1 — Install Foreman & Puppet repos
###############################################
install_repos() {
    step "Installing Foreman & Puppet repositories"
    dnf clean all
    dnf install -y https://yum.theforeman.org/releases/3.18/el9/x86_64/foreman-release.rpm
    dnf install -y https://yum.puppet.com/puppet8-release-el-9.noarch.rpm
    dnf repolist enabled
    dnf upgrade -y
}

###############################################
# Step 2 — Install Foreman packages
###############################################
install_packages() {
    step "Installing Foreman packages"
    dnf install -y foreman-installer
    dnf install -y rubygem-smart_proxy_realm_ad_plugin.noarch
}

###############################################
# Step 3 — Run Foreman installer
###############################################
run_installer() {
    if [[ "$SKIP_INSTALLER" = true ]]; then
        warn "Skipping foreman-installer as requested"
        return
    fi

    step "Running foreman-installer"
    foreman-installer \
        --foreman-proxy-realm=true \
        --foreman-proxy-realm-provider="$REALM_PROVIDER"
}

###############################################
# Step 4 — Validate services
###############################################
validate_services() {
    step "Validating Foreman services"
    systemctl status foreman || err "Foreman service failed"
    systemctl status foreman-proxy || err "Foreman Proxy service failed"
}

###############################################
# Step 5 — Show logs
###############################################
show_logs() {
    if [[ "$SKIP_LOGS" = true ]]; then
        warn "Skipping logs as requested"
        return
    fi

    step "Showing Foreman logs"
    tail -n 50 /var/log/foreman-proxy/proxy.log || warn "Proxy log missing"
    tail -n 50 /var/log/foreman-installer/foreman.log || warn "Installer log missing"
}

###############################################
# Main
###############################################
main() {
    install_repos
    install_packages
    run_installer
    validate_services
    show_logs

    step "Foreman installation helper completed"
}

main "$@"


