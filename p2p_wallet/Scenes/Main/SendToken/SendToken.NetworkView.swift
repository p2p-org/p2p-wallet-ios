//
//  SendToken.NetworkView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit
import RxSwift

extension SendToken {
    class NetworkView: UIStackView {
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var coinImageView = UIImageView(width: 44, height: 44, image: nil)
        private lazy var networkNameLabel = UILabel(text: "<network>", textSize: 17, weight: .semibold)
        private lazy var feeLabel = UILabel(text: "<transfer fee:>", textSize: 13, numberOfLines: 0, textAlignment: .right)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .top, distribution: .fill)
            addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    networkNameLabel
                    UIStackView(axis: .horizontal, spacing: 0, alignment: .top, distribution: .fill) {
                        UILabel(text: L10n.transferFee + ": ", textSize: 13, textColor: .textSecondary)
                            .withContentHuggingPriority(.required, for: .horizontal)
                            .padding(.init(x: 0, y: 2))
                        feeLabel
                    }
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setUp(network: SendToken.Network, prices: [String: Double]) {
            coinImageView.image = network.icon
            networkNameLabel.text = L10n.network(network.rawValue.uppercaseFirst)
            
            let attributedText = NSMutableAttributedString()
            
            let fees = network.defaultFees
            
            if fees.map(\.amount).reduce(0.0, +) == 0 {
                attributedText
                    .text("\(Defaults.fiat.symbol)0", size: 13, weight: .semibold, color: .attentionGreen)
            } else {
                attributedText
                    .append(network.defaultFees.attributedString(prices: prices, textSize: 13, tokenColor: .textSecondary, separator: ",\n", lineSpacing: 2, alignment: .left))
            }
            feeLabel.attributedText = attributedText
        }
    }
}
