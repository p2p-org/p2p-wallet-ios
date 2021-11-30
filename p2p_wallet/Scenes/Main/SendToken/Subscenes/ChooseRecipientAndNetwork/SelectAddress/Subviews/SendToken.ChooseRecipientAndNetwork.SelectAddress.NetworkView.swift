//
//  SendToken.ChooseRecipientAndNetwork.SelectAddress.NetworkView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit

extension SendToken.ChooseRecipientAndNetwork.SelectAddress {
    final class NetworkView: WLFloatingPanelView {
        lazy var coinImageView = CoinLogoImageView(size: 44, cornerRadius: 12)
        lazy var networkNameLabel = UILabel(text: "<network>", textSize: 17, weight: .semibold)
        lazy var descriptionLabel = UILabel(text: "<transfer fee:>", textSize: 13)
        
        convenience init(forConvenience: Void) {
            self.init(contentInset: .init(all: 18))
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.alignment = .center
            stackView.addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    networkNameLabel
                    descriptionLabel
                }
                UIView.defaultNextArrow()
            }
        }
    }
}
