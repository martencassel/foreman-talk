#!/usr/bin/env bash
set -euo pipefail

###############################################
# Logging helpers
###############################################
log()  { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
step() { echo -e "\n\e[36m=== $* ===\e[0m\n"; }

###############################################
# Defaults
###############################################
REGISTER=true
USERNAME="marten.cassel@conoa.se"
ORG="6698658"

PACKAGES="vim adcli nmap net-tools"

###############################################
# Help screen
###############################################
usage() {
    cat <<EOF
Usage: $0 [options]

Prepare a RHEL system for Foreman installation by:
  • Stopping firewalld
  • Registering with subscription-manager
  • Running dnf update
  • Installing base packages

Options:
  --username EMAIL        Red Hat subscription username (default: $USERNAME)
  --org ID                Red Hat organization ID (default: $ORG)
  --no-register           Skip subscription-manager registration
  --packages "LIST"       Additional packages to install
  -h, --help              Show this help screen

Examples:
  $0
  $0 --no-register
  $0 --username admin@example.com --org 1234567
  $0 --packages "vim git curl"

EOF
    exit 0
}

###############################################
# Argument parsing
###############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --username) USERNAME="$2"; shift 2 ;;
        --org) ORG="$2"; shift 2 ;;
        --no-register) REGISTER=false; shift ;;
        --packages) PACKAGES="$2"; shift 2 ;;
        -h|--help) usage ;;
        *)
            err "Unknown option: $1"
            usage ;;
    esac
done

###############################################
# Step 1 — Stop firewalld
###############################################
stop_firewalld() {
    step "Stopping firewalld"
    sudo systemctl stop firewalld --now || warn "firewalld not running"
}

###############################################
# Step 2 — Register system
###############################################
register_system() {
    if [[ "$REGISTER" = false ]]; then
        warn "Skipping subscription-manager registration"
        return
    fi

    step "Registering system with subscription-manager"
    sudo subscription-manager register \
        --username "$USERNAME" \
        --org "$ORG"
}

###############################################
# Step 3 — Update system
###############################################
update_system() {
    step "Updating system"
    sudo dnf update -y
}

###############################################
# Step 4 — Install base packages
###############################################
install_packages() {
    step "Installing base packages"
    sudo dnf install -y $PACKAGES
}

###############################################
# Main
###############################################
main() {
    stop_firewalld
    register_system
    update_system
    install_packages

    step "System preparation complete"
}

main "$@"

