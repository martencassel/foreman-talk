#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# CONFIGURATION
# -------------------------------

INTERNAL_IP="172.31.18.203/20"
INTERNAL_GW="172.31.16.1"

EXTERNAL_IP="192.168.0.26/24"
EXTERNAL_GW="192.168.0.1"

DNS_SERVERS="8.8.8.8 1.1.1.1"

TEST_IP="1.1.1.1"   # Used to detect external NIC

# -------------------------------
# DETECT INTERFACES
# -------------------------------

echo "Detecting network interfaces…"
IFS=$'\n' read -r -d '' -a IFACES < <(nmcli -t -f DEVICE,STATE device | grep ":connected" | cut -d: -f1 && printf '\0')

if [[ ${#IFACES[@]} -lt 2 ]]; then
  echo "Error: Expected at least 2 NICs, found ${#IFACES[@]}."
  exit 1
fi

echo "Found interfaces:"
printf " - %s\n" "${IFACES[@]}"

# -------------------------------
# DETERMINE WHICH NIC HAS INTERNET
# -------------------------------

detect_external_nic() {
  for nic in "${IFACES[@]}"; do
    echo "Testing outbound connectivity on $nic…"
    if ping -I "$nic" -c1 -W1 "$TEST_IP" &>/dev/null; then
      echo " → $nic has external internet access."
      echo "$nic"
      return
    fi
  done
  echo "Error: No NIC with external internet detected."
  exit 1
}

EXTERNAL_NIC=$(detect_external_nic)

# INTERNAL NIC = the other one
if [[ "${IFACES[0]}" == "$EXTERNAL_NIC" ]]; then
  INTERNAL_NIC="${IFACES[1]}"
else
  INTERNAL_NIC="${IFACES[0]}"
fi

echo "External NIC: $EXTERNAL_NIC"
echo "Internal NIC: $INTERNAL_NIC"

# -------------------------------
# APPLY INTERNAL NIC CONFIG
# -------------------------------

echo "Configuring INTERNAL NIC ($INTERNAL_NIC)…"

nmcli connection modify "$INTERNAL_NIC" ipv4.addresses "$INTERNAL_IP"
nmcli connection modify "$INTERNAL_NIC" ipv4.gateway "$INTERNAL_GW"
nmcli connection modify "$INTERNAL_NIC" ipv4.method manual
nmcli connection modify "$INTERNAL_NIC" ipv6.method ignore
nmcli connection modify "$INTERNAL_NIC" ipv4.route-metric 102

# -------------------------------
# APPLY EXTERNAL NIC CONFIG
# -------------------------------

echo "Configuring EXTERNAL NIC ($EXTERNAL_NIC)…"

nmcli connection modify "$EXTERNAL_NIC" ipv4.addresses "$EXTERNAL_IP"
nmcli connection modify "$EXTERNAL_NIC" ipv4.gateway "$EXTERNAL_GW"
nmcli connection modify "$EXTERNAL_NIC" ipv4.method manual
nmcli connection modify "$EXTERNAL_NIC" ipv6.method ignore

nmcli connection modify "$EXTERNAL_NIC" ipv4.dns "$DNS_SERVERS"
nmcli connection modify "$EXTERNAL_NIC" ipv4.ignore-auto-dns yes
nmcli connection modify "$EXTERNAL_NIC" ipv4.route-metric 101

# -------------------------------
# RESTART CONNECTIONS
# -------------------------------

echo "Restarting connections…"

nmcli connection down "$INTERNAL_NIC" || true
nmcli connection up "$INTERNAL_NIC"

nmcli connection down "$EXTERNAL_NIC" || true
nmcli connection up "$EXTERNAL_NIC"

echo "Network configuration complete."


