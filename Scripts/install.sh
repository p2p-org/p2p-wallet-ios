# Install xcodegen
brew install xcodegen

# Run xcodegen (pod install will be called right after to get swiftgen)
xcodegen

# Run swiftgen for the first time
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen to remove build error (file missing before swiftgen)
xcodegen

# Open project
xed .