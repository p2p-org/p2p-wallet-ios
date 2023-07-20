xcodebuild docbuild \
  -scheme KeyAppUI \
  -destination generic/platform=iOS \
  OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path KeyAppUI --output-path docs"