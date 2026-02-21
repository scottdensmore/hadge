#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPER_SETTINGS_PATH="${SCRIPT_DIR}/DeveloperSettings.xcconfig"
SECRETS_PATH="${SCRIPT_DIR}/Hadge/Secrets.xcconfig"

NON_INTERACTIVE=false
DEV_TEAM_ID="${DEV_TEAM_ID:-}"
ORG_IDENTIFIER="${ORG_IDENTIFIER:-}"
GITHUB_CLIENT_ID="${GITHUB_CLIENT_ID:-}"
GITHUB_CLIENT_SECRET="${GITHUB_CLIENT_SECRET:-}"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Creates:
  - DeveloperSettings.xcconfig
  - Hadge/Secrets.xcconfig

Options:
  --non-interactive              Run without prompts (requires all values)
  --dev-team-id <id>             Apple Developer Team ID
  --org-identifier <value>       Reverse-domain identifier (e.g. com.example)
  --github-client-id <id>        GitHub OAuth App client ID
  --github-client-secret <value> GitHub OAuth App client secret
  -h, --help                     Show this help

Environment fallbacks:
  DEV_TEAM_ID
  ORG_IDENTIFIER
  GITHUB_CLIENT_ID
  GITHUB_CLIENT_SECRET
EOF
}

escape_xcconfig_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

require_option_value() {
  local option="$1"
  local value="${2:-}"
  if [ -z "${value}" ]; then
    echo "error: ${option} requires a value" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    --dev-team-id)
      require_option_value "$1" "${2:-}"
      DEV_TEAM_ID="$2"
      shift 2
      ;;
    --org-identifier)
      require_option_value "$1" "${2:-}"
      ORG_IDENTIFIER="$2"
      shift 2
      ;;
    --github-client-id)
      require_option_value "$1" "${2:-}"
      GITHUB_CLIENT_ID="$2"
      shift 2
      ;;
    --github-client-secret)
      require_option_value "$1" "${2:-}"
      GITHUB_CLIENT_SECRET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ "${NON_INTERACTIVE}" = false ]; then
  cat << "EOF"
.__                 .___  ____           
|  |__  _____     __| _/ / ___\   ____   
|  |  \ \__  \   / __ | / /_/  >_/ __ \  
|   Y  \ / __ \_/ /_/ | \___  / \  ___/  
|___|  /(____  /\____ |/_____/   \___  > 
     \/      \/      \/              \/  
                                         

EOF

  echo "This script will create DeveloperSettings.xcconfig and Hadge/Secrets.xcconfig."
  echo
  echo "Missing values will be prompted."
  echo
  read -r -p "Press enter to get started."
fi

if [ "${NON_INTERACTIVE}" = true ]; then
  missing=()
  [ -z "${DEV_TEAM_ID}" ] && missing+=("DEV_TEAM_ID/--dev-team-id")
  [ -z "${ORG_IDENTIFIER}" ] && missing+=("ORG_IDENTIFIER/--org-identifier")
  [ -z "${GITHUB_CLIENT_ID}" ] && missing+=("GITHUB_CLIENT_ID/--github-client-id")
  [ -z "${GITHUB_CLIENT_SECRET}" ] && missing+=("GITHUB_CLIENT_SECRET/--github-client-secret")

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "error: --non-interactive mode requires all values." >&2
    printf 'missing: %s\n' "${missing[@]}" >&2
    exit 1
  fi
else
  if [ -z "${DEV_TEAM_ID}" ]; then
    echo "1. What is your Developer Team ID? You can get this from developer.apple.com."
    read -r DEV_TEAM_ID
  fi

  if [ -z "${ORG_IDENTIFIER}" ]; then
    echo "2. What is your organisation identifier? e.g. com.developername"
    read -r ORG_IDENTIFIER
  fi

  if [ -z "${GITHUB_CLIENT_ID}" ]; then
    echo "3. What is your GitHub App Client ID? See README for how to create a GitHub OAuth App."
    read -r GITHUB_CLIENT_ID
  fi

  if [ -z "${GITHUB_CLIENT_SECRET}" ]; then
    echo "4. What is your GitHub App Client Secret? See README for how to create a GitHub OAuth App."
    read -r -s GITHUB_CLIENT_SECRET
    echo
  fi
fi

ESCAPED_CLIENT_ID="$(escape_xcconfig_string "${GITHUB_CLIENT_ID}")"
ESCAPED_CLIENT_SECRET="$(escape_xcconfig_string "${GITHUB_CLIENT_SECRET}")"

echo "Creating ${DEVELOPER_SETTINGS_PATH}"
cat <<EOF > "${DEVELOPER_SETTINGS_PATH}"
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = ${DEV_TEAM_ID}
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = ${ORG_IDENTIFIER}
EOF

echo "Creating ${SECRETS_PATH}"
cat <<EOF > "${SECRETS_PATH}"
GITHUB_CLIENT_ID = "${ESCAPED_CLIENT_ID}"
GITHUB_CLIENT_SECRET = "${ESCAPED_CLIENT_SECRET}"
EOF

chmod 600 "${DEVELOPER_SETTINGS_PATH}" "${SECRETS_PATH}"
echo "Done."
