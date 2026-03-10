#!/bin/bash
#
# generate-keytab.sh
#
# Wrapper around ktutil for generating a service‑account keytab
# in a fully non‑interactive, automation‑safe way.
#

set -euo pipefail

###############################################
# Help screen
###############################################
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -r, --realm REALM            Kerberos realm (e.g. EXAMPLE.COM)
  -s, --service ACCOUNT        Service account name (e.g. foreman-proxy)
  -p, --password PASSWORD      Service account password
  -o, --output FILE            Output keytab path (default: /tmp/${SERVICE_ACCOUNT}.keytab)
  -h, --help                   Show this help screen

Example:
  $0 -r EXAMPLE.COM -s foreman-proxy -p 'P@ssw0rd!' -o /tmp/realm.keytab

EOF
    exit 1
}

###############################################
# Default values
###############################################
REALM_DOMAIN=""
SERVICE_ACCOUNT=""
SERVICE_PASSWORD=""
OUTPUT_FILE=""

###############################################
# Argument parsing
###############################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--realm)
            REALM_DOMAIN="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE_ACCOUNT="$2"
            shift 2
            ;;
        -p|--password)
            SERVICE_PASSWORD="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

###############################################
# Validate required arguments
###############################################
if [[ -z "$REALM_DOMAIN" || -z "$SERVICE_ACCOUNT" || -z "$SERVICE_PASSWORD" ]]; then
    echo "ERROR: Missing required arguments."
    usage
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="/tmp/${SERVICE_ACCOUNT}.keytab"
fi

PRINCIPAL="${SERVICE_ACCOUNT}@${REALM_DOMAIN}"

echo "Generating keytab for principal: $PRINCIPAL"
echo "Output file: $OUTPUT_FILE"

###############################################
# Generate keytab using ktutil
###############################################
ktutil <<EOF
addent -password -p ${PRINCIPAL} -k 1 -e aes256-cts-hmac-sha1-96
${SERVICE_PASSWORD}
addent -password -p ${PRINCIPAL} -k 1 -e aes128-cts-hmac-sha1-96
${SERVICE_PASSWORD}
wkt ${OUTPUT_FILE}
quit
EOF

echo "Keytab written to: ${OUTPUT_FILE}"

###############################################
# Validate keytab
###############################################
echo "Validating keytab with kinit..."
if kinit -k -t "${OUTPUT_FILE}" "${PRINCIPAL}" >/dev/null 2>&1; then
    echo "SUCCESS: Keytab is valid."
else
    echo "ERROR: Keytab validation failed."
    exit 2
fi

exit 0

