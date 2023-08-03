#!/bin/bash

# move to working folder
cd "${PROJECT_DIR}"

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
    key_name=$(echo "$value" | sed 's/[[:space:]]//g')
    last_key="\"key_name\":$key_name,\"platforms\":[\"ios\"],\"translations\":[{\"language_iso\":\"en\",\"translation\":$value}]"
done <<< "$new_lines"
json_payload+="{$last_key}]}"

# Log the JSON payload
echo "$json_payload"

# Send the keys and values to Lokalise API
# curl -X POST "https://api.lokalise.com/api2/projects/$project_id/keys" \
#      -H "Content-Type: application/json" \
#      -H "x-api-token: $lokalise_api_token" \
#      -d "$json_payload"