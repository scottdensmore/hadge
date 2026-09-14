#!/usr/bin/env bash

set -euo pipefail

SRCROOT="${SRCROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OUTPUT_DIR="${SRCROOT}/Hadge/Generated"
OUTPUT_FILE="${OUTPUT_DIR}/Secrets.generated.swift"
SECRETS_XCCONFIG="${SRCROOT}/Hadge/Secrets.xcconfig"

CLIENT_ID="${GITHUB_CLIENT_ID:-}"
CLIENT_SECRET="${GITHUB_CLIENT_SECRET:-}"

# If not passed via environment, attempt to read from Secrets.xcconfig
if [ -z "${CLIENT_ID}" ] && [ -f "${SECRETS_XCCONFIG}" ]; then
  CLIENT_ID=$(sed -n 's/^[[:space:]]*GITHUB_CLIENT_ID[[:space:]]*=[[:space:]]*//p' "${SECRETS_XCCONFIG}" | tr -d '\r\n"')
fi

if [ -z "${CLIENT_SECRET}" ] && [ -f "${SECRETS_XCCONFIG}" ]; then
  CLIENT_SECRET=$(sed -n 's/^[[:space:]]*GITHUB_CLIENT_SECRET[[:space:]]*=[[:space:]]*//p' "${SECRETS_XCCONFIG}" | tr -d '\r\n"')
fi

# Strip any surrounding double quotes
CLIENT_ID="${CLIENT_ID%\"}"
CLIENT_ID="${CLIENT_ID#\"}"
CLIENT_SECRET="${CLIENT_SECRET%\"}"
CLIENT_SECRET="${CLIENT_SECRET#\"}"

mkdir -p "${OUTPUT_DIR}"

cat <<EOF > "${OUTPUT_FILE}"
// Generated during build - do not edit directly
struct Secrets {
  static let gitHubClientId = "${CLIENT_ID}"
  static let gitHubClientSecret = "${CLIENT_SECRET}"
}
EOF
