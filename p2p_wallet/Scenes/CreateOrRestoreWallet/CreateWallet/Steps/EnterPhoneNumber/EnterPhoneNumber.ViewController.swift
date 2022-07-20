// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

extension EnterPhoneNumber {
    final class ViewController: BaseViewController {
        let sol: String
        let eth: String
        let deviceShare: String

        init(sol: String, eth: String, deviceShare: String) {
            self.sol = sol
            self.eth = eth
            self.deviceShare = deviceShare

            super.init()
        }

        override func build() -> UIView {
            BECenter {
                UILabel(text: "Enter phone number screen")
                UILabel(text: sol)
                UILabel(text: eth)
                UILabel(text: deviceShare)
            }
        }
    }
}
