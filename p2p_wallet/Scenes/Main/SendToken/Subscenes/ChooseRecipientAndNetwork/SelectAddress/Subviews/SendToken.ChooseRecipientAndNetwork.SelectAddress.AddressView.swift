//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.AddressView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class AddressView: UIStackView {
        lazy var nameLabel = UILabel(text: "<username>", textSize: 17, weight: .semibold)
        lazy var addressLabel = UILabel(text: "<address>", textSize: 13, textColor: .textSecondary)
        lazy var clearButton = UIImageView(width: 17, height: 17, image: .crossIcon)
        
        convenience init(forConvenience: Void) {
            self.init(axis: .horizontal, spacing: 8, alignment: .center, distribution: .fill)
            self.addArrangedSubviews {
                UIImageView(width: 24, height: 24, image: .walletButtonSmall, tintColor: .white)
                    .padding(.init(all: 10), backgroundColor: .h5887ff, cornerRadius: 20)
                UIStackView(axis: .vertical, spacing: 6, alignment: .fill, distribution: .fill) {
                    nameLabel
                    addressLabel
                }
                clearButton
            }
        }
    }
}
