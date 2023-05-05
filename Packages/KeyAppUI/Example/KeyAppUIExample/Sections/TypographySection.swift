// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import KeyAppUI

class TypographySection: BECompositionView {
    override func build() -> UIView {
        BEVStack {
            UILabel(text: "Typography", textSize: 22).padding(.init(only: .top, inset: 20))

            for style in UIFont.Style.allCases {
                UILabel()
                    .withAttributedText(UIFont.text(style.rawValue, of: style, weight: .regular))
                    .onTap { [weak self] in self?.shareCodeTemplate(style, .bold) }
            }

            for style in UIFont.Style.allCases {
                UILabel()
                    .withAttributedText(UIFont.text(style.rawValue, of: style, weight: .bold))
                    .onTap { [weak self] in self?.shareCodeTemplate(style, .bold) }
            }
        }
    }

    func shareCodeTemplate(_ style: UIFont.Style, _ weight: UIFont.Weight) {
        let code = """
        UILabel()
            .withAttributedText(UIFont.text(<#String#>, of: .\(style), weight: .\(weight))
        """

        CodeTemplate.share(code: code)
    }
}
