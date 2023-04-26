# Install xcodegen
brew install xcodegen swiftgen swiftlint swiftformat periphery

# Run xcodegen
xcodegen

# Run swiftgen for the first time
/opt/homebrew/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen to remove build error (file missing before swiftgen)
xcodegen

# Open project
xed .