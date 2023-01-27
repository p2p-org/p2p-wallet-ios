# Download Config.xcconfig
echo "Download Config.xcconfig"
if [[ -z "${XCCONFIG_URL}" ]]; then
	# XCCONFIG_URL is not available
	echo "XCCONFIG_URL missing. Set this value: "
	echo "export XCCONFIG_URL=<Ask team leader for this value>"
	exit 1
else
	curl -o ./p2p_wallet/Config.xcconfig ${XCCONFIG_URL}
fi

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