// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

class RestoreResultViewController: BaseViewController {
    let sol: String
    let eth: String

    init(sol: String, eth: String) {
        self.sol = sol
        self.eth = eth
        super.init()
    }

    override func build() -> UIView {
        BECenter {
            BEVStack {
                UILabel(text: "Result")
                UILabel(text: sol)
                UILabel(text: eth)
            }
        }
    }
}
