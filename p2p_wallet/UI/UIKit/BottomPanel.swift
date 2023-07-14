// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation
import BEPureLayout
import SwiftUI

class BottomPanel: BECompositionView {
    let child: UIView

    override init() {
        child = UIView()
        super.init(frame: .zero)
    }

    required init(@BEViewBuilder builder: Builder) {
        child = builder().build()
        super.init(frame: .zero)
    }
    
    override func build() -> UIView {
        BEContainer {
            child
        }
            .backgroundColor(color: .init(resource: .night))
            .roundCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 24)
    }
}
