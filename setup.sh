#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPER_SETTINGS_PATH="${SCRIPT_DIR}/DeveloperSettings.xcconfig"
SECRETS_PATH="${SCRIPT_DIR}/Hadge/Secrets.xcconfig"

cat << "EOF"
.__                 .___  ____           
|  |__  _____     __| _/ / ___\   ____   
|  |  \ \__  \   / __ | / /_/  >_/ __ \  
|   Y  \ / __ \_/ /_/ | \___  / \  ___/  
|___|  /(____  /\____ |/_____/   \___  > 
     \/      \/      \/              \/  
                                         

EOF

echo This script will create DeveloperSettings.xcconfig and Hadge/Secrets.xcconfig.
echo 
echo We need to ask a few questions first.
echo 
read -r -p "Press enter to get started."


# Get the user's Developer Team ID
echo 1. What is your Developer Team ID? You can get this from developer.apple.com.
read -r devTeamID

# Get the user's Org Identifier
echo 2. What is your organisation identifier? e.g. com.developername
read -r devOrgName

# Get the user's Developer Team ID
echo 3. What is your GitHub App Client ID? See README for how to create a GitHub OAuth App
read -r githubClientId

# Get the user's Org Identifier
echo 4. What is your GitHub App Client Secret? See README for how to create a GitHub OAuth App
read -r githubClientSecret

echo "Creating ${DEVELOPER_SETTINGS_PATH}"

cat <<file > "${DEVELOPER_SETTINGS_PATH}"
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = $devTeamID
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = $devOrgName
file

echo "Creating ${SECRETS_PATH}"

cat <<file > "${SECRETS_PATH}"
GITHUB_CLIENT_ID = "$githubClientId"
GITHUB_CLIENT_SECRET = "$githubClientSecret"
file

echo Done! 
