xcodebuild docbuild \
  -scheme KeyAppUI \
  -destination generic/platform=iOS \
  OTHER_DOCC_FLAGS="--transform-for-static-hosting --output-path docs"