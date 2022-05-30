echo "\n🛠  XcodeGen post-script: started... 🛠\n"

git submodule update --init --recursive
git config core.hooksPath .githooks
chmod -R +x .githooks
pod install
Pods/swiftgen/bin/swiftgen config run --config swiftgen.yml

echo "\n✅ XcodeGen post-script: finished. ✅\n"