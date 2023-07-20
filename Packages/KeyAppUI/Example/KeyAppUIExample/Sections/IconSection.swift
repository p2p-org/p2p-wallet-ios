// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import KeyAppUI

class IconSection: BECompositionView {
    override func build() -> UIView {
        BEVStack {
            UILabel(text: "Icons", textSize: 22).padding(.init(only: .top, inset: 20))
            BEVStack {
                for iconsChunk in Asset.MaterialIcon.allImages.chunks(ofCount: 12) {
                    BEHStack {
                        for icon in iconsChunk {
                            UIImageView(image: icon.image, contentMode: .scaleAspectFill)
                                .frame(width: 24, height: 24)
                        }
                        UIView.spacer
                    }
                }
            }
        }
    }
}
