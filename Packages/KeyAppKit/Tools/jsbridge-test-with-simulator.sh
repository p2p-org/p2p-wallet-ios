#
# // Copyright 2022 P2P Validator Authors. All rights reserved.
# // Use of this source code is governed by a MIT-style license that can be
# // found in the LICENSE file.
#

cd Tests/SimulatorIntegration/ || exit
xcodebuild test -sdk iphoneos -scheme "JSBridgeTests" -destination "platform=iOS Simulator,name=IPhone 11"