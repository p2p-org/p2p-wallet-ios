#!/bin/bash

# Get the absolute path to the parent folder containing "p2p_wallet/Resources"
parent_folder=$(cd "$(dirname "$0")" && cd .. && pwd)

input_file="unusedText.txt"
output_file="processedText.txt"

# Remove all lines that don't start with "/// " and trim out "/// " for other lines
grep "^/// " "$input_file" | sed 's/^\/\/\/ //' > "$output_file"

# Read all lines from "processedText.txt" into the array "keys_to_remove"
keys_to_remove=()
while IFS= read -r line || [[ -n "$line" ]]; do
    keys_to_remove+=("$line")
done < "$output_file"

# Discard any local changes in the file before processing
discard_changes() {
    local file="$1"
    git -C "$parent_folder/p2p_wallet/Resources" checkout -- "$file"
}

# Function to remove lines containing keys from "Localizable.strings" files
function remove_keys_from_localizable_strings {
    local file="$1"
    for key in "${keys_to_remove[@]}"; do
        echo "$key"
        sed -i.bak "/\"$key\" = \".*\";/d" "$file"
    done
    rm "$file.bak"
}

# Find and process all "Localizable.strings" files in "p2p_wallet/Resources/*.lproj/" folders
find "$parent_folder/p2p_wallet/Resources" -type f -name "Localizable.strings" | grep -E "/[a-z]+\.lproj/" | while read -r file; do
    discard_changes "$file"
    remove_keys_from_localizable_strings "$file"
    echo "$file"
done

# rm "$output_file"