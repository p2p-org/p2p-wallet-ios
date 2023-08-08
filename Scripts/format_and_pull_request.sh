#!/bin/bash

# Function to check if a pull request already exists with given base and head branches
check_existing_pull_request() {
  local base_branch="$1"
  local head_branch="$2"
  
  local github_token="$GITHUB_TOKEN"

  local url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls"
  local query="?base=$base_branch&head=$head_branch"
  
  local response=$(curl -s -H "Authorization: token $github_token" "$url$query")
  echo "$response"
}

# Function to create a pull request using GitHub API
create_pull_request() {
  local base_branch="$1"
  local head_branch="$2"
  local title="$3"
  
  local github_token="$GITHUB_TOKEN"

  local url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls"
  local data="{\"title\":\"$title\",\"base\":\"$base_branch\",\"head\":\"$head_branch\"}"

  local pr_response=$(curl -s -X POST -H "Authorization: token $github_token" -d "$data" "$url")
  local pr_url=$(echo "$pr_response" | jq -r .html_url)
  echo "$pr_url"
}

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Run swiftformat on the p2p_wallet directory
swiftformat p2p_wallet

# Check if any .swift files require formatting
if [[ $(git status --porcelain | grep '^ M' | grep '\.swift$') ]]; then
  # Create a new branch for formatting changes
  new_formatting_branch="swiftformat/$current_branch"

  # Create a new branch and force push formatting changes
  git checkout -b "$new_formatting_branch"
  git add -A
  git commit -m "fix(swiftformat): Apply Swiftformat changes"
  git push -f origin "$new_formatting_branch"

  # Check if a pull request with the same base and head branches already exists
  existing_prs=$(check_existing_pull_request "$current_branch" "$new_formatting_branch")
  
  if [ "$(echo "$existing_prs" | jq length)" -eq 0 ]; then
    # Create a pull request using GitHub API
    pr_title="[Swiftformat] Correct format for $new_formatting_branch"
    pr_url=$(create_pull_request "$current_branch" "$new_formatting_branch" "$pr_title")
  
    # Print formatted message for GitHub Actions failure with green PR URL
    echo "::error::Formatting changes detected. Created pull request: $pr_url"
    exit 1
  else
    # Print formatted message for GitHub Actions failure with existing PR information
    existing_pr_url=$(echo "$existing_prs" | jq -r '.[0].html_url')
    echo "::warning::A pull request already exists with base branch '$current_branch' and head branch '$new_formatting_branch'. PR URL: $existing_pr_url"
    exit 0
  fi
else
  # Print formatted message for GitHub Actions success
  echo "No formatting changes detected."
  exit 0
fi
