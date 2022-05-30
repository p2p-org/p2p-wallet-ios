# Run xcodegen
xcodegen

# Run pod install
pod install

# Run swiftgen for the first time
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen && pod install
xcodegen && pod install

# Open project
xed .