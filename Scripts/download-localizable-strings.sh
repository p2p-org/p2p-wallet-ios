#!/bin/bash

# Check if the necessary environment variables are set
if [[ -z "${LOKALISE_API_TOKEN}" || -z "${LOKALISE_PROJECT_ID}" || -z "${SUPPORTED_LANGUAGUES}" ]]; then
  echo "Please set the environment variables SUPPORTED_LANGUAGUES, LOKALISE_API_TOKEN, and LOKALISE_PROJECT_ID."
  exit 1
fi

supported_languages="${SUPPORTED_LANGUAGUES}"
echo "Download strings for supported languages: $supported_languages"

# JSON data to be sent in the request
json_data='{
  "format": "strings",
  "export_empty_as": "base",
  "all_platforms": false,
  "filter_langs": '"$supported_languages"',
  "replace_breaks": true,
  "escape_percent": true,
  "add_newline_eof": true
}'

# Print the JSON data being sent in the request
echo "Request JSON Data:"
echo "$json_data"

# Get JSON response
response=$(curl -X "POST" "https://api.lokalise.com/api2/projects/${LOKALISE_PROJECT_ID}/files/download" \
     -H "X-Api-Token: ${LOKALISE_API_TOKEN}" \
     -H "Content-Type: application/json" \
     -d "$json_data")

# Print the JSON response
echo "Response JSON Data:"
echo "$response"

# Extract the bundle_url from the JSON response
bundle_url=$(echo "$response" | jq -r '.bundle_url')

# Download the file and save it as a .zip bundle
curl -L "$bundle_url" -o "localization_bundle.zip"

# Extract the ZIP file to p2p_wallet/Resources, force replace files if already exist
unzip -o "localization_bundle.zip" -d "p2p_wallet/Resources"

# Remove downloaded file
rm "localization_bundle.zip"

# Check if there are any changes in *.lproj folders and commit the updated localization
if [[ $(git status --porcelain "p2p_wallet/Resources" | grep -E '\.lproj/') ]]; then
    git add "p2p_wallet/Resources"
    git commit -m "feat(lokalise): Update localization from Lokalise"
    echo "Changes detected and committed."
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$current_branch"
fi
