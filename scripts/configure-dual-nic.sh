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
# Default configuration
###############################################
INTERNAL_IP="172.31.18.203/20"
INTERNAL_GW="172.31.16.1"

EXTERNAL_IP="192.168.0.26/24"
EXTERNAL_GW="192.168.0.1"

DNS_SERVERS="8.8.8.8 1.1.1.1"
TEST_IP="1.1.1.1"

###############################################
# Help screen
###############################################
usage() {
    cat <<EOF
Usage: $0 [options]

Automatically detect two NICs, determine which one has external internet
access, and configure internal/external network settings using nmcli.

Options:
  --internal-ip CIDR       Internal NIC IP address (default: $INTERNAL_IP)
  --internal-gw IP         Internal gateway (default: $INTERNAL_GW)

  --external-ip CIDR       External NIC IP address (default: $EXTERNAL_IP)
  --external-gw IP         External gateway (default: $EXTERNAL_GW)

  --dns "IP1 IP2"          DNS servers for external NIC (default: "$DNS_SERVERS")

  --test-ip IP             IP used to detect external NIC (default: $TEST_IP)

  -h, --help               Show this help screen

Description:
  This script:
    • Detects all connected NICs
    • Identifies which NIC has outbound internet access
    • Assigns the external IP/gateway/DNS to that NIC
    • Assigns the internal IP/gateway to the other NIC
    • Applies route metrics to ensure correct routing
    • Restarts both connections cleanly

Examples:
  $0
  $0 --internal-ip 10.0.0.10/24 --internal-gw 10.0.0.1
  $0 --external-ip 192.168.1.50/24 --dns "8.8.8.8 9.9.9.9"

EOF
    exit 0
}

###############################################
# Argument parsing
###############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --internal-ip) INTERNAL_IP="$2"; shift 2 ;;
        --internal-gw) INTERNAL_GW="$2"; shift 2 ;;
        --external-ip) EXTERNAL_IP="$2"; shift 2 ;;
        --external-gw) EXTERNAL_GW="$2"; shift 2 ;;
        --dns)         DNS_SERVERS="$2"; shift 2 ;;
        --test-ip)     TEST_IP="$2"; shift 2 ;;
        -h|--help)     usage ;;
        *)
            err "Unknown option: $1"
            usage ;;
    esac
done

###############################################
# Detect interfaces
###############################################
step "Detecting network interfaces"

IFS=$'\n' read -r -d '' -a IFACES < <(
    nmcli -t -f DEVICE,STATE device |
    grep ":connected" |
    cut -d: -f1 &&
    printf '\0'
)

if [[ ${#IFACES[@]} -lt 2 ]]; then
    err "Expected at least 2 NICs, found ${#IFACES[@]}."
    exit 1
fi

log "Found interfaces:"
printf " - %s\n" "${IFACES[@]}"

###############################################
# Determine external NIC
###############################################
detect_external_nic() {
    for nic in "${IFACES[@]}"; do
        log "Testing outbound connectivity on $nic"
        if ping -I "$nic" -c1 -W1 "$TEST_IP" &>/dev/null; then
            log " → $nic has external internet access"
            echo "$nic"
            return
        fi
    done
    err "No NIC with external internet detected"
    exit 1
}

EXTERNAL_NIC=$(detect_external_nic)

# INTERNAL NIC = the other one
if [[ "${IFACES[0]}" == "$EXTERNAL_NIC" ]]; then
    INTERNAL_NIC="${IFACES[1]}"
else
    INTERNAL_NIC="${IFACES[0]}"
fi

log "External NIC: $EXTERNAL_NIC"
log "Internal NIC: $INTERNAL_NIC"

###############################################
# Configure internal NIC
###############################################
step "Configuring INTERNAL NIC ($INTERNAL_NIC)"

nmcli connection modify "$INTERNAL_NIC" ipv4.addresses "$INTERNAL_IP"
nmcli connection modify "$INTERNAL_NIC" ipv4.gateway "$INTERNAL_GW"
nmcli connection modify "$INTERNAL_NIC" ipv4.method manual
nmcli connection modify "$INTERNAL_NIC" ipv6.method ignore
nmcli connection modify "$INTERNAL_NIC" ipv4.route-metric 102

###############################################
# Configure external NIC
###############################################
step "Configuring EXTERNAL NIC ($EXTERNAL_NIC)"

nmcli connection modify "$EXTERNAL_NIC" ipv4.addresses "$EXTERNAL_IP"
nmcli connection modify "$EXTERNAL_NIC" ipv4.gateway "$EXTERNAL_GW"
nmcli connection modify "$EXTERNAL_NIC" ipv4.method manual
nmcli connection modify "$EXTERNAL_NIC" ipv6.method ignore

nmcli connection modify "$EXTERNAL_NIC" ipv4.dns "$DNS_SERVERS"
nmcli connection modify "$EXTERNAL_NIC" ipv4.ignore-auto-dns yes
nmcli connection modify "$EXTERNAL_NIC" ipv4.route-metric 101

###############################################
# Restart connections
###############################################
step "Restarting connections"

nmcli connection down "$INTERNAL_NIC" || true
nmcli connection up "$INTERNAL_NIC"

nmcli connection down "$EXTERNAL_NIC" || true
nmcli connection up "$EXTERNAL_NIC"

step "Network configuration complete"
