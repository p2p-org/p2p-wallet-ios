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
        // MARK: - Dependencies
        private let viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType
        
        // MARK: - Subviews
        private lazy var coinImageView = UIImageView(width: 44, height: 44, image: nil)
        private lazy var networkNameLabel = UILabel(text: "<network>", textSize: 17, weight: .semibold)
        private lazy var descriptionLabel = UILabel(text: "<transfer fee:>", textSize: 13)
        
        init(viewModel: SendTokenChooseRecipientAndNetworkSelectAddressViewModelType) {
            self.viewModel = viewModel
            super.init(contentInset: .init(all: 18))
            stackView.axis = .horizontal
            stackView.spacing = 12
            stackView.alignment = .center
            stackView.addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    networkNameLabel
                    descriptionLabel
                }
            }
        }
        
        func setUp(network: SendToken.Network, fee: SendToken.Fee) {
            coinImageView.image = network.icon
            networkNameLabel.text = L10n.network(network.rawValue.uppercaseFirst)
            
            let attributedText = NSMutableAttributedString()
                .text(L10n.transferFee + ": ", size: 13, color: .textSecondary)
            
            if fee.amount == 0 {
                attributedText
                    .text("$0", size: 13, weight: .semibold, color: .attentionGreen)
            } else {
                let amountInUSD = fee.amount * viewModel.getRenBTCPrice()
                attributedText
                    .text("\(fee.amount.toString(maximumFractionDigits: 9)) \(fee.unit)", size: 13, color: .textSecondary)
                    .text(" (~$\(amountInUSD.toString(maximumFractionDigits: 9)))", size: 13, color: .textSecondary)
            }
            descriptionLabel.attributedText = attributedText
        }
    }
}
