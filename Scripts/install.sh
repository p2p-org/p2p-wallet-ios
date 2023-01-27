# Download Config.xcconfig
echo "Download Config.xcconfig"
if [[ -z $XCCONFIG_URL ]]; then
	# XCCONFIG_URL is not available
	echo "XCCONFIG_URL missing. Set this value: "
	echo "export XCCONFIG_URL=<Ask team leader for this value>"
	exit 1
else
	curl -o ./p2p_wallet/Config.xcconfig $XCCONFIG_URL
fi

# Install swiftgen
brew install swiftgen

# Run swiftgen for the first time
swiftgen config run --config swiftgen.yml

# Run xcodegen
xcodegen

# Open project
xed .