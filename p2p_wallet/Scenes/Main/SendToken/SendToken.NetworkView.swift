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
        func setUp(network: SendToken.Network, payingWallet: Wallet?, feeInfo: SendToken.FeeInfo?, prices: [String: Double]) -> Self {
            coinImageView.image = network.icon
            networkNameLabel.text = L10n.network(network.rawValue.uppercaseFirst)
            
            let attributedText = NSMutableAttributedString()
                .text(L10n.transferFee + ": ", size: 13, color: .textSecondary)
            
            if let feeInfo = feeInfo {
                attributedText
                    .append(
                        feeInfo
                            .attributedString(
                                payingWallet: payingWallet,
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

private extension SendToken.FeeInfo {
    func attributedString(
        payingWallet wallet: Wallet?,
        prices: [String: Double],
        textSize: CGFloat = 15,
        tokenColor: UIColor = .textBlack,
        fiatColor: UIColor = .textSecondary,
        attributedSeparator: NSAttributedString = NSAttributedString(string: "\n")
    ) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString()
        
        // if empty
        if feeAmount.transaction == 0 && (feeAmount.others == nil || feeAmount.others?.isEmpty == true) {
            attributedText
                .text("\(Defaults.fiat.symbol)0", size: 13, weight: .semibold, color: .attentionGreen)
            return attributedText
        }
        
        // total (in SOL)
        let totalFeeInSOL = feeAmount.transaction.convertToBalance(decimals: 9)
        let totalFeeInUSD = totalFeeInSOL * prices[wallet?.token.symbol ?? ""]
        attributedText
            .text("\(totalFeeInSOL.toString(maximumFractionDigits: 9)) \(wallet?.token.symbol ?? "")", size: textSize, color: tokenColor)
            .text(" (~\(Defaults.fiat.symbol)\(totalFeeInUSD.toString(maximumFractionDigits: 2)))", size: textSize, color: fiatColor)
        
        // other fees
        if let others = feeAmount.others {
            attributedText.append(attributedSeparator)
            for (index, fee) in others.enumerated() {
                let amountInUSD = fee.amount * prices[fee.unit]
                attributedText
                    .text("\(fee.amount.toString(maximumFractionDigits: 9)) \(fee.unit)", size: textSize, color: tokenColor)
                    .text(" (~\(Defaults.fiat.symbol)\(amountInUSD.toString(maximumFractionDigits: 2)))", size: textSize, color: fiatColor)
                if index < others.count - 1 {
                    attributedText
                        .append(attributedSeparator)
                }
            }
        }
        return attributedText
    }
}
