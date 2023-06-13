#!/bin/bash

# ANSI escape codes for colorizing and bold logs (macOS-compatible)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BOLD=$(tput bold)
NC=$(tput sgr0) # Reset formatting

# Log
echo "${GREEN}${BOLD}==>${NC} Checking ${GREEN}${BOLD}Config.xcconfig${NC} file"

source_file="./p2p_wallet/Info.plist"
check_file="./p2p_wallet/Config.xcconfig"
exclude_strings=("DEVELOPMENT_LANGUAGE" "EXECUTABLE_NAME" "PRODUCT_BUNDLE_IDENTIFIER" "MARKETING_VERSION" "CURRENT_PROJECT_VERSION" "")

output_file="./Scripts/checkSecrets-output.txt"

# Step 1: Find strings in the source file that start with "$("
awk -F'\\$\\(|\\)' '{ for (i=2; i<=NF; i+=2) print $i }' "$source_file" > "$output_file"

# Step 2: Check if the strings exist in the check file
while IFS= read -r string; do
    # Exclude these cases in exclude_strings
    if ! [[ " ${exclude_strings[*]} " =~ " $string " ]]; then
        # Check if secrets exists
        if ! grep -qF "$string" "$check_file"; then
            echo "${RED}${BOLD}Secret \"$string\" not found in \"$check_file\"${NC}"
            exit 1
        fi
    fi
done < "$output_file"

echo "${GREEN}${BOLD}All secrets have been set! 🎉${NC}"

# Clean up temporary files
rm "$output_file"