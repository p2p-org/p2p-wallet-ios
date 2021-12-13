//
//  OrcaSwapV2.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxCocoa
import RxSwift

struct OrcaSwapV2 {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet(validMints: Set<String>, excludedSourceWalletPubkey: String?)
        case settings
        case chooseSlippage
        case choosePayFeeToken(tokenName: String?)
        case swapFees
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
        case back
    }
    
    enum VerificationError: String {
        case swappingIsNotAvailable
        case sourceWalletIsEmpty
        case destinationWalletIsEmpty
        case canNotSwapToItSelf
        case tradablePoolsPairsNotLoaded
        case tradingPairNotSupported
        case feesIsBeingCalculated
        case couldNotCalculatingFees
        case inputAmountIsEmpty
        case inputAmountIsNotValid
        case insufficientFunds
        case estimatedAmountIsNotValid
        case bestPoolsPairsIsEmpty
        case slippageIsNotValid
        case nativeWalletNotFound
        case notEnoughSOLToCoverFees
        case notEnoughBalanceToCoverFees
        case unknown
    }
}

// MARK: - Helpers
extension OrcaSwapV2 {
    // MARK: - Helpers
    static func isFeeRelayerEnabled(source: Wallet?, destination: Wallet?) -> Bool {
        guard let source = source,
              let destination = destination
        else {
            return false
        }
        return !source.isNativeSOL && !destination.isNativeSOL && Defaults.payingToken != .nativeSOL
    }
    
    static func createSectionView(
        title: String? = nil,
        label: UIView? = nil,
        contentView: UIView?,
        rightView: UIView? = .defaultNextArrow(),
        addSeparatorOnTop: Bool = true
    ) -> UIStackView {
        let innerStackView = UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
            label ?? UILabel(
                text: title,
                textSize: 13,
                weight: .medium,
                textColor: .textSecondary
            )
        }
        
        if let contentView = contentView {
            innerStackView.addArrangedSubview(contentView)
        }
        
        let stackView = UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
            innerStackView
        }
        
        if let rightView = rightView {
            stackView.addArrangedSubview(rightView)
        }
        
        if !addSeparatorOnTop {
            return stackView
        } else {
            return UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill) {
                UIView.defaultSeparator()
                stackView
            }
        }
    }
    
    static func slippageAttributedText(
        slippage: Double
    ) -> NSAttributedString {
        if slippage > .maxSlippage {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                .text(" ", weight: .medium)
                .text(L10n.slippageExceedsMaximum, weight: .medium, color: .red)
        } else if slippage > .frontrunSlippage && slippage <= .maxSlippage {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
                .text(" ", weight: .medium)
                .text(L10n.yourTransactionMayBeFrontrun, weight: .medium, color: .attentionGreen)
        } else {
            return NSMutableAttributedString()
                .text((slippage * 100).toString(maximumFractionDigits: 9) + "%", weight: .medium)
        }
    }
}
