//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.AddressInputView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class AddressInputView: UIStackView {
        lazy var textField = createTextField()
        lazy var clearButton = UIImageView(width: 17, height: 17, image: .crossIcon)
        
        convenience init(forConvenience: Void) {
            self.init(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
            self.addArrangedSubviews {
                UIImageView(width: 24, height: 24, image: .buttonSearch, tintColor: .a3a5ba)
                    .padding(.init(all: 14), backgroundColor: .f6f6f8, cornerRadius: 20)
                textField
                clearButton
            }
        }
        
        // MARK: - Helpers
        private func createTextField() -> UITextField {
            let textField = UITextField(
                backgroundColor: .clear,
                placeholder: nil,
                autocorrectionType: .none,
                autocapitalizationType: UITextAutocapitalizationType.none,
                spellCheckingType: .no
            )
            textField.attributedPlaceholder = NSAttributedString(
                string: L10n.p2PUsernameSOLAddress,
                attributes: [
                    .foregroundColor: UIColor.a3a5ba.onDarkMode(.h5887ff),
                    .font: UIFont.systemFont(ofSize: 15, weight: .medium)
                ]
            )
            textField.font = .systemFont(ofSize: 15, weight: .medium)
            return textField
        }
    }
}
