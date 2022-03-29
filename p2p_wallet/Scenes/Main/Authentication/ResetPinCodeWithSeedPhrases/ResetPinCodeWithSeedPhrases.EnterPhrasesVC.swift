//
//  ResetPinCodeWithSeedPhrases.EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/06/2021.
//

import Foundation

extension ResetPinCodeWithSeedPhrases {
    class EnterPhrasesVC: WLEnterPhrasesVC {
        override func setUp() {
            super.setUp()
            var index = 0
            stackView.insertArrangedSubviews(at: &index) {
                UIStackView(axis: .horizontal, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
                    UIImageView(width: 24, height: 24, image: .securityKey, tintColor: .white),
                    UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 21, weight: .semibold),
                ])
                    .padding(.init(all: 20))
                UIView.separator(height: 1, color: .separator)
            }
        }
    }
}
