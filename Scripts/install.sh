# Install xcodegen, swiftgen, swiftlint, swiftformat
brew install xcodegen swiftgen swiftlint swiftformat

# Install periphery
brew install peripheryapp/periphery/periphery

# Resolve homebrew installation folder for non-m1 mac (ci)
# For non-m1, homebrew tools would be located in /usr/local/bin
# So we create symbolic links from /usr/local/bin to /opt/homebrew/bin for each tool
if [[ ! $(uname -m) == 'arm64' ]]; then
	# log
	echo "Create a symbolic link from /usr/local/bin to /opt/homebrew/bin"

	# create /opt/homebrew/bin if not exists
	mkdir -p /opt/homebrew/bin

	# Create symbolic links
	ln -s /usr/local/bin/xcodegen /opt/homebrew/bin/xcodegen
	ln -s /usr/local/bin/swiftgen /opt/homebrew/bin/swiftgen
	ln -s /usr/local/bin/swiftlint /opt/homebrew/bin/swiftlint
	ln -s /usr/local/bin/swiftformat /opt/homebrew/bin/swiftformat
	ln -s /usr/local/bin/periphery /opt/homebrew/bin/periphery
fi

# Run xcodegen
xcodegen

# Run swiftgen for the first time
/opt/homebrew/bin/swiftgen config run --config swiftgen.yml

# Re-run xcodegen to remove build error (file missing before swiftgen)
xcodegen

# Open project
xed .
