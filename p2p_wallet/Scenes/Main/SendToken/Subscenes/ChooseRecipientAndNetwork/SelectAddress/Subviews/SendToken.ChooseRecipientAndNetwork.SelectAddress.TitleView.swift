//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.TitleView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class TitleView: UIStackView {
        lazy var scanQrCodeButton = createButton(image: .scanQr, text: L10n.scanQR)
        lazy var pasteQrCodeButton = createButton(image: .buttonPaste, text: L10n.paste.uppercaseFirst)
        
        convenience init(forConvenience: Void) {
            self.init(axis: .horizontal, spacing: 16, alignment: .top, distribution: .fill)
            self.addArrangedSubviews {
                UILabel(text: L10n.to, textSize: 15, weight: .medium)
                UIView.spacer
                scanQrCodeButton
                UIView(width: 1, height: 20, backgroundColor: .f6f6f8.onDarkMode(.white))
                pasteQrCodeButton
            }
        }
        
        private func createButton(image: UIImage, text: String) -> UIView {
            UIStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill) {
                UIImageView(width: 20, height: 20, image: image, tintColor: .h5887ff)
                UILabel(text: text, textSize: 15, weight: .medium, textColor: .h5887ff)
            }
        }
    }
}
