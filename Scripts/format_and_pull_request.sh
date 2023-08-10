#!/bin/bash

# Function to check if an opened pull request already exists with given base and head branches
check_existing_pull_request() {
  local base_branch="$1"
  local head_branch="$2"
  
  local github_token="$GITHUB_TOKEN"

  local url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls"
  local query="?base=$base_branch&head=$head_branch&state=open"
  
  local response=$(curl -s -H "Authorization: token $github_token" "$url$query")
  echo "$response"
}

# Function to create a pull request using GitHub API
create_pull_request() {
  local base_branch="$1"
  local head_branch="$2"
  local title="$3"
  local body="$4"
  
  local github_token="$GITHUB_TOKEN"

  local url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls"
  local data="{\"title\":\"$title\", \"body\":\"$body\",\"base\":\"$base_branch\",\"head\":\"$head_branch\"}"

  local pr_response=$(curl -s -X POST -H "Authorization: token $github_token" -d "$data" "$url")
  local pr_url=$(echo "$pr_response" | jq -r .html_url)
  echo "$pr_url"
}

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Run swiftformat on the p2p_wallet directory
swiftformat p2p_wallet
swiftformat Packages/KeyAppKit

# Check if any .swift files require formatting
if [[ $(git status --porcelain | grep '^ M' | grep '\.swift$') ]]; then
  # Create a new branch for formatting changes
  new_formatting_branch="swiftformat/$current_branch"

  # Create a new branch and force push formatting changes
  git checkout -B "$new_formatting_branch"
  git status --porcelain | grep '^ M' | grep '\.swift$' | awk '{print $2}' | xargs git add
  git commit -m "fix(swiftformat): Apply Swiftformat changes"
  git push -f origin "$new_formatting_branch"

  # Check if an opened pull request with the same base and head branches already exists
  existing_prs=$(check_existing_pull_request "$current_branch" "$new_formatting_branch")
  
  if [ "$(echo "$existing_prs" | jq length)" -eq 0 ]; then
    # Create a pull request using GitHub API
    pr_title="[Swiftformat] Correct format for $current_branch"
    pr_body="Fix code format for $current_branch"
    pr_url=$(create_pull_request "$current_branch" "$new_formatting_branch" "$pr_title" "$pr_body")

    # Get the pull request number from the URL
    pr_number=$(echo "$pr_url" | awk -F'/' '{print $NF}')
    
    # Add the "swiftformat" label to the pull request using the GitHub API
    label_data="{\"labels\":[\"swiftformat\"]}"
    label_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$pr_number/labels"
    curl -X POST -H "Authorization: token $GITHUB_TOKEN" -d "$label_data" "$label_url"
  
    # Print formatted message for GitHub Actions failure with clickable PR URL
    echo "::warning::Unformatted code detected. Don't worry, I fixed them for you here: $pr_url"
    echo "PR_URL=${pr_url}" >> $GITHUB_ENV
    exit 0
  else
    # Print formatted message for GitHub Actions failure with existing PR information
    existing_pr_url=$(echo "$existing_prs" | jq -r '.[0].html_url')
    echo "::warning::Unformatted code detected. Don't worry, I fixed them for you here: $existing_pr_url"
    echo "PR_URL=${existing_pr_url}" >> $GITHUB_ENV
    exit 0
  fi
else
  # Print formatted message for GitHub Actions success
  echo "No formatting changes detected."
  exit 0
fi
