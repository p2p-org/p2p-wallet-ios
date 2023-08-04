#!/bin/bash

# Check if the necessary environment variables are set
if [[ -z "${LOKALISE_API_TOKEN}" || -z "${LOKALISE_PROJECT_ID}" ]]; then
  echo "Please set the environment variables LOKALISE_API_TOKEN and LOKALISE_PROJECT_ID."
  exit 1
fi

# Define the tag name
tag_name="lokalise/downloaded"

# Function to get the timestamp of the tag's creation
get_creation_timestamp() {
  git log -1 --format="%ct" "$tag_name"
}

# Get the timestamp of the tag's creation
timestamp=$(get_creation_timestamp)

# Convert timestamp to the desired date format (YYYY-MM-DD)
creation_date=$(python -c "import datetime; print(datetime.datetime.fromtimestamp($timestamp).strftime('%Y-%m-%d'))")
echo "$creation_date"

# Read the MARKETING_VERSION from project.yml and extract only the number
marketing_version=$(grep "MARKETING_VERSION" project.yml | cut -d ':' -f 2 | tr -d '[:space:]' | tr -d '"')

# Function to download localization files in JSON format from Lokalise
download_json_files() {
  local date_param="$1"
  local supported_languages="${SUPPORTED_LANGUAGUES}"

  # Download JSON files
  response=$(curl -X "POST" "https://api.lokalise.com/api2/projects/${LOKALISE_PROJECT_ID}/files/download" \
       -H "X-Api-Token: ${LOKALISE_API_TOKEN}" \
       -H "Content-Type: application/json" \
       -d $'{
              "format": "strings",
              "export_empty_as": "base",
              "all_platforms": false,
              "filter_lang": "'"$supported_languages"'",
              "replace_breaks": true,
              "escape_percent": true,
              "include_tags": ["'"$marketing_version"'"]
            }')

  # Extract the bundle_url from the JSON response
  bundle_url=$(echo "$response" | jq -r '.bundle_url')

  # Download the file and save it as a .zip bundle
  curl -L "$bundle_url" -o "localization_bundle.zip"

  # Extract the ZIP file to p2p_wallet/Resources
  unzip "localization_bundle.zip" -d "p2p_wallet/Resources"

  # Remove downloaded file
  rm "localization_bundle.zip"
}

# Download JSON files and create the .zip bundle
download_json_files "$creation_date"

echo "Localization bundle downloaded for the creation date: $creation_date"
