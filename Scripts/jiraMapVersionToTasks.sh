#!/bin/bash

# Check if the release parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <release>"
    exit 1
fi

# Check if JIRA_USER_EMAIL and JIRA_API_TOKEN environment variables are set
if [ -z "$JIRA_USER_EMAIL" ] || [ -z "$JIRA_API_TOKEN" ]; then
    echo "Please set the JIRA_USER_EMAIL and JIRA_API_TOKEN environment variables."
    exit 1
fi

# Run git log commands and concatenate the outputs into log_output
git fetch origin main
log_output=$(git log main.."$1" --grep='PWN' --regexp-ignore-case --pretty=format:%s)

# Extract the release version from the provided parameter
release=$(echo "$1" | sed 's/^release\///')

# Extract strings matching the format PWN-[number] (ignoring case)
regex="PWN-[0-9]+"
matches=($(echo "$log_output" | grep -ioE "$regex"))

# Convert matches to uppercase and remove duplicates
unique_matches=($(echo "${matches[@]}" | tr '[:lower:]' '[:upper:]' | tr ' ' '\n' | sort -u))

# Loop through the unique matches and search for Jira tasks
for match in "${unique_matches[@]}"; do
    echo "Searching for Jira tasks with '$match'..."
    # Make a REST API call to Jira to retrieve the issue details
    response=$(curl -s -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" -X GET \
        "$JIRA_BASE_URL/rest/api/2/issue/$match")

    # Parse the response and extract the task key
    key=$(echo "$response" | jq -r '.key')

    # Print the task key
    if [ "$key" != "null" ]; then
        echo "- $key"

        # Update the fix version of the Jira issue
        update_response=$(curl -s -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" -X PUT \
            -H "Content-Type: application/json" \
            --data "{\"update\":{\"fixVersions\":[{\"set\":[{\"name\":\"iOS $release\"}]}]}}" \
            "$JIRA_BASE_URL/rest/api/2/issue/$key")

        if [ "$(echo "$update_response" | jq -r '.id')" != "null" ]; then
            echo "  - Fix version updated successfully"
        else
            echo "  - Failed to update fix version"
            echo "$update_response"
        fi

    else
        echo "- No Jira task found for '$match'"
    fi

    echo
done
