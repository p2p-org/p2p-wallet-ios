// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import BEPureLayout
import UIKit

class NumpadButton: BEView {
    // MARK: - Constant

    private let textSize: CGFloat = 32
    private let customBgColor = PincodeStateColor(normal: .clear, tapped: Asset.Colors.night.color)
    private let textColor = PincodeStateColor(normal: Asset.Colors.night.color, tapped: Asset.Colors.snow.color)

    // MARK: - Subviews

    lazy var label = UILabel(font: .font(of: .largeTitle, weight: .regular), textColor: textColor.normal)

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        backgroundColor = customBgColor.normal

        addSubview(label)
        label.autoCenterInSuperview()
    }

    func setHighlight(value: Bool) {
        if value {
            layer.backgroundColor = customBgColor.tapped.cgColor
            label.textColor = textColor.tapped
        } else {
            layer.backgroundColor = customBgColor.normal.cgColor
            label.textColor = textColor.normal
        }
    }

    func animateTapping() {
        layer.backgroundColor = customBgColor.tapped.cgColor
        label.textColor = textColor.tapped
        UIView.animate(withDuration: 0.05) {
            self.layer.backgroundColor = self.customBgColor.normal.cgColor
            self.label.textColor = self.textColor.normal
        }
    }
}
