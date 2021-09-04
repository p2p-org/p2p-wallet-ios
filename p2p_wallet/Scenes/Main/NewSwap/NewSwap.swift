//
//  SerumSwap.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct NewSwap {
    enum NavigatableScene {
        case chooseSourceWallet
        case chooseDestinationWallet
        case settings
        case chooseSlippage
        case swapFees
        case processTransaction(request: Single<ProcessTransactionResponseType>, transactionType: ProcessTransaction.TransactionType)
    }
    
    // MARK: - Helpers
    static func createSectionView(
        title: String? = nil,
        label: UIView? = nil,
        contentView: UIView,
        rightView: UIView? = UIImageView(width: 6, height: 12, image: .nextArrow, tintColor: .h8b94a9.onDarkMode(.white)
        )
            .padding(.init(x: 9, y: 6)),
        addSeparatorOnTop: Bool = true
    ) -> UIStackView {
        let stackView = UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill) {
            UIStackView(axis: .vertical, spacing: 5, alignment: .fill, distribution: .fill) {
                label ?? UILabel(
                    text: title,
                    textSize: 13,
                    weight: .medium,
                    textColor: .textSecondary
                )
                contentView
            }
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

protocol NewSwapScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

protocol NewSwapViewModelType: WalletDidSelectHandler, NewSwapSettingsViewModelType, NewSwapSwapFeesViewModelType {
    // Input
    var inputAmountSubject: PublishRelay<String?> {get}
    var estimatedAmountSubject: PublishRelay<String?> {get}
    
    // Drivers
    var navigationDriver: Driver<NewSwap.NavigatableScene?> {get}
    var isLoadingDriver: Driver<Bool> {get}
    
    var sourceWalletDriver: Driver<Wallet?> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var inputAmountDriver: Driver<Double?> {get}
    
    var destinationWalletDriver: Driver<Wallet?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    
    var exchangeRateDriver: Driver<Double?> {get}
    
    var slippageDriver: Driver<Double?> {get}
    
    var feesDriver: Driver<[FeeType: SwapFee]> {get}
    
    var payingTokenDriver: Driver<PayingToken> {get}
    
    var errorDriver: Driver<String?> {get}
    
    var isSwapPairValidDriver: Driver<Bool> {get}
    
    var isExchangeRateReversedDriver: Driver<Bool> {get}
    
    var isSwappableDriver: Driver<Bool> {get}
    
    // Signals
    var useAllBalanceDidTapSignal: Signal<Double?> {get}
    
    // Actions
    func reload()
    func navigate(to: NewSwap.NavigatableScene)
    func useAllBalance()
    func log(_ event: AnalyticsEvent)
    func swapSourceAndDestination()
    func reverseExchangeRate()
    func authenticateAndSwap()
    func changeSlippage(to slippage: Double)
    func changePayingToken(to payingToken: PayingToken)
    func getSourceWallet() -> Wallet?
    func providerSignatureView() -> UIView
}

protocol NewSwapViewModelAPIClient {
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: NewSwapViewModelAPIClient {}
