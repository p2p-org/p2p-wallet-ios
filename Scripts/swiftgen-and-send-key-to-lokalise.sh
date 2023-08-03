#!/bin/bash

# move to working folder
cd "${PROJECT_DIR}"

# Read the MARKETING_VERSION from project.yml and extract only the number
marketing_version=$(grep "MARKETING_VERSION" project.yml | cut -d ':' -f 2 | tr -d '[:space:]' | tr -d '"')

# Run swiftgen first
echo "==> Run swiftgen"
/opt/homebrew/bin/swiftgen config run --config swiftgen.yml

# Get the new lines from Localizable.strings using git diff
changes=$(git diff HEAD -- p2p_wallet/Resources/Base.lproj/Localizable.strings)

# Extract new lines from the git diff
new_lines=$(echo "$changes" | grep "^[+]" | grep -v "^+++" | cut -c2-)

# Parse values from the new lines and build the JSON payload for the last key-value pair
json_payload="{\"keys\": ["
last_key=""
while IFS= read -r line; do
    value=$(echo "$line" | awk -F '=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
    key_name=$(echo "$value")
    
    # Check if key_name or value is empty
    if [ -z "$key_name" ] || [ -z "$value" ]; then
        echo "Error: key_name or value is empty."
        exit 1
    fi

    last_key="\"key_name\":$key_name,\"platforms\":[\"ios\"],\"tags\":[\"$marketing_version\"],\"translations\":[{\"language_iso\":\"en\",\"translation\":$value}]"
done <<< "$new_lines"
json_payload+="{$last_key}]}"

# Log the JSON payload
echo "$json_payload"

# Read the API token and project ID from Config.xcconfig
lokalise_api_token=$(grep "LOKALISE_API_TOKEN" p2p_wallet/Config.xcconfig | cut -d '=' -f 2 | tr -d ' ')
project_id=$(grep "LOKALISE_PROJECT_ID" p2p_wallet/Config.xcconfig | cut -d '=' -f 2 | tr -d ' ')

# Send the keys and values to Lokalise API
curl "https://api.lokalise.com/api2/projects/$project_id/keys" \
     -H "X-Api-Token: $lokalise_api_token" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     -d "$json_payload"