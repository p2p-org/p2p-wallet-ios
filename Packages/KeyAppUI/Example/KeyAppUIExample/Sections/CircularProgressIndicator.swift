// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import Foundation
import KeyAppUI

class CircularProgressIndicatorSection: BECompositionView {
    override func build() -> UIView {
        BEVStack(alignment: .leading) {
            UILabel(text: "Circular progress indicator", textSize: 22).padding(.init(only: .top, inset: 20))
            BEHStack {
                CircularProgressIndicator()
                    .frame(width: 22, height: 22)
                    .padding(.init(only: .right, inset: 8))
                CircularProgressIndicator(foregroundCircularColor: .black)
                    .frame(width: 22, height: 22)
                    .padding(.init(only: .right, inset: 8))
                CircularProgressIndicator(foregroundCircularColor: .white)
                    .frame(width: 22, height: 22)
            }
        }
    }
}
