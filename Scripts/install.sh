# Install xcodegen
brew install xcodegen

# Run xcodegen
xcodegen

# Run swiftgen for the first time
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen
xcodegen

# Open project
xed .