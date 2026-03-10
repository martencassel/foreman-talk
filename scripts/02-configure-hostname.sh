#!/bin/bash
set -euo pipefail

###############################################
# Logging helpers
###############################################
log()  { echo -e "\e[32m[INFO]\e[0m $*"; }
err()  { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }
step() { echo -e "\n\e[36m=== $* ===\e[0m\n"; }

###############################################
# Help screen
###############################################
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -h, --hostname NAME       Hostname to set (required)
  -i, --ip ADDRESS          IP address to map in /etc/hosts (optional)
  -a, --alias NAME          Additional alias for /etc/hosts (optional)
  -f, --force               Overwrite existing hostname entry in /etc/hosts
  -H, --help                Show this help screen

Examples:
  $0 --hostname foreman --ip 172.31.16.1
  $0 -h foreman -i 172.31.16.1 -a foreman.lab
  $0 -h foreman --force

EOF
    exit 1
}

###############################################
# Defaults
###############################################
HOSTNAME=""
IPADDR=""
ALIAS=""
FORCE=false

###############################################
# Argument parsing
###############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        -i|--ip)
            IPADDR="$2"
            shift 2
            ;;
        -a|--alias)
            ALIAS="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -H|--help)
            usage
            ;;
        *)
            err "Unknown option: $1"
            usage
            ;;
    esac
done

###############################################
# Validate required args
###############################################
if [[ -z "$HOSTNAME" ]]; then
    err "Hostname is required."
    usage
fi

###############################################
# Step 1 — Set hostname
###############################################
configure_hostname() {
    step "Setting system hostname"
    sudo hostnamectl set-hostname "$HOSTNAME"
    log "Hostname set to: $HOSTNAME"
}

###############################################
# Step 2 — Update /etc/hosts
###############################################
update_hosts() {
    step "Updating /etc/hosts"

    if [[ -z "$IPADDR" ]]; then
        warn "No IP provided; skipping /etc/hosts update"
        return
    fi

    ENTRY="$IPADDR $HOSTNAME"
    [[ -n "$ALIAS" ]] && ENTRY="$ENTRY $ALIAS"

    if grep -q "$HOSTNAME" /etc/hosts && [[ "$FORCE" = false ]]; then
        err "Hostname already exists in /etc/hosts. Use --force to overwrite."
        exit 1
    fi

    # Remove existing entries if force is enabled
    if [[ "$FORCE" = true ]]; then
        sudo sed -i "/$HOSTNAME/d" /etc/hosts
    fi

    echo "$ENTRY" | sudo tee -a /etc/hosts > /dev/null
    log "Added to /etc/hosts: $ENTRY"
}

###############################################
# Main
###############################################
main() {
    configure_hostname
    update_hosts
    step "Hostname configuration complete"
}

main


