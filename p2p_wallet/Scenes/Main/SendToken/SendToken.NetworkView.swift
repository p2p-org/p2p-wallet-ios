//
//  SendToken.NetworkView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/11/2021.
//

import Foundation
import UIKit
import RxSwift
import SolanaSwift

extension SendToken {
    class NetworkView: UIStackView {
        // MARK: - Dependencies
        private let disposeBag = DisposeBag()
        
        // MARK: - Subviews
        private lazy var coinImageView = UIImageView(width: 44, height: 44, image: nil)
        private lazy var networkNameLabel = UILabel(text: "<network>", textSize: 17, weight: .semibold)
        private lazy var feeLabel = UILabel(text: "<transfer fee:>", textSize: 13, numberOfLines: 2)
        
        init() {
            super.init(frame: .zero)
            
            set(axis: .horizontal, spacing: 12, alignment: .center, distribution: .fill)
            addArrangedSubviews {
                coinImageView
                UIStackView(axis: .vertical, spacing: 4, alignment: .fill, distribution: .fill) {
                    networkNameLabel
                    feeLabel
                }
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @discardableResult
        func setUp(network: SendToken.Network, feeAmount: SolanaSDK.FeeAmount?, prices: [String: Double]) -> Self {
            coinImageView.image = network.icon
            networkNameLabel.text = L10n.network(network.rawValue.uppercaseFirst)
            
            let attributedText = NSMutableAttributedString()
                .text(L10n.transferFee + ": ", size: 13, color: .textSecondary)
            
            if let feeAmount = feeAmount {
                attributedText
                    .append(
                        feeAmount
                            .attributedString(
                                prices: prices,
                                textSize: 13,
                                tokenColor: .textSecondary,
                                attributedSeparator: NSMutableAttributedString()
                                    .text(",\n", size: 13, color: .textSecondary)
                                    .text(L10n.transferFee + ": ", size: 13, color: .clear)
                            )
                    )
            }
            
            feeLabel.attributedText = attributedText
            
            return self
        }
    }
}
