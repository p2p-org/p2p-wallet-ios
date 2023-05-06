if [ "${CONFIGURATION}" = "Release" ]; then
  echo "Swiftlint is disabled in Release mode"
  exit 0
fi

START_DATE=$(date +"%s")

SWIFT_LINT=/opt/homebrew/bin/swiftlint

if [[ -e "${SWIFT_LINT}" ]]; then
    echo "[I] Found SwiftLint at ${SWIFT_LINT}"
fi

if [[ ! -e "${SWIFT_LINT}" ]]; then
    echo "[!] SwifLint is not installed."
    echo "[!] Expected location is '${SWIFT_LINT}'"
    echo "[!] Please install it. eg. 'brew install swiftlint'"
    exit 1
fi

echo "[I] SwiftLint version: $(${SWIFT_LINT} version)"

# Run for unstaged, staged, new files, excluded for deleted files
git diff --diff-filter=d --name-only -- "*.swift" | while read filename; do
    $SWIFT_LINT lint --path "$filename";
done

git diff --cached --diff-filter=d --name-only -- "*.swift" | while read filename; do
    $SWIFT_LINT lint --path "$filename";
done

git ls-files --others --exclude-standard -- "*.swift" | while read filename; do
    $SWIFT_LINT lint --path "$filename";
done

END_DATE=$(date +"%s")

DIFF=$(($END_DATE - $START_DATE))
echo "SwiftLint took $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds to complete."
