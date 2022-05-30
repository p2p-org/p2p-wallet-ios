# Install xcodegen
brew install xcodegen

# Run xcodegen
xcodegen

# Run pod install first to gen swiftgen in Pods
pod install

# Run swiftgen for the first time
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen && pod install to remove build error
xcodegen && pod install

# Open project
xed .