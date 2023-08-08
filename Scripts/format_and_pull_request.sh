#!/bin/bash

# Function to recursively find the next available branch name
get_next_branch_name() {
  local branch_name="$1"
  local suffix=0
  local new_branch_name="$branch_name"
  
  while git rev-parse --quiet --verify "refs/heads/$new_branch_name" >/dev/null; do
    ((suffix++))
    new_branch_name="${branch_name}${suffix}"
  done

  echo "$new_branch_name"
}

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Run swiftformat on the p2p_wallet directory
swiftformat p2p_wallet

# Check if any .swift files require formatting
if [[ $(git status --porcelain | grep '^ M' | grep '\.swift$') ]]; then
  # Generate a new branch name for formatting changes
  formatting_branch="${current_branch}-swiftformat"
  new_formatting_branch=$(get_next_branch_name "$formatting_branch")

  # Create a new branch for formatting changes
  git checkout -b "$new_formatting_branch"

  # Add only Swift files to the staging area
  git add $(git status --porcelain | grep '^ M' | grep '\.swift$' | awk '{print $2}')

  # Commit the formatting changes
  git commit -m "fix(swiftformat): Apply Swiftformat changes"

  # Push the changes to the remote repository
  git push origin "$new_formatting_branch"

  # Print formatted message for GitHub Actions failure
  echo "::error::Formatting changes detected. Created pull request for SwiftFormat changes in branch '$new_formatting_branch'."
  exit 1
else
  # Print formatted message for GitHub Actions success
  echo "No formatting changes detected."
  exit 0
fi
