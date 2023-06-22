#!/bin/bash

# Check if the release parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <release>"
    exit 1
fi

# Extract the release parameter
release="$1"

# Run git log command and store the output in a variable
log_output=$(git log "$release"..develop --grep='PWN' --regexp-ignore-case --pretty=format:%s)

# Extract strings matching the format PWN-[number] (ignoring case)
regex="PWN-[0-9]+"
matches=($(echo "$log_output" | grep -ioE "$regex"))

# Convert matches to uppercase and remove duplicates
unique_matches=($(echo "${matches[@]}" | tr '[:lower:]' '[:upper:]' | tr ' ' '\n' | sort -u))

# Loop through the unique matches and print each one
for match in "${unique_matches[@]}"; do
    echo "$match"
done

