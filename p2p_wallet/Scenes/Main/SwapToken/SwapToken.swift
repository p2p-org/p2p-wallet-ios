//
//  SwapToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/08/2021.
//

import Foundation
import RxSwift
import RxCocoa

struct SwapToken {
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

protocol SwapTokenScenesFactory {
    func makeChooseWalletViewController(customFilter: ((Wallet) -> Bool)?, showOtherWallets: Bool, handler: WalletDidSelectHandler) -> ChooseWallet.ViewController
    func makeProcessTransactionViewController(transactionType: ProcessTransaction.TransactionType, request: Single<ProcessTransactionResponseType>) -> ProcessTransaction.ViewController
}

protocol SwapTokenViewModelType: WalletDidSelectHandler, SwapTokenSettingsViewModelType, SwapTokenSwapFeesViewModelType {
    // Input
    var inputAmountSubject: PublishRelay<String?> {get}
    var estimatedAmountSubject: PublishRelay<String?> {get}
    
    // Drivers
    var navigationDriver: Driver<SwapToken.NavigatableScene?> {get}
    var initialStateDriver: Driver<LoadableState> {get}
    
    var sourceWalletDriver: Driver<Wallet?> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var inputAmountDriver: Driver<Double?> {get}
    
    var destinationWalletDriver: Driver<Wallet?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    
    var exchangeRateDriver: Driver<Loadable<Double>> {get}
    
    var slippageDriver: Driver<Double?> {get}
    
    var feesDriver: Driver<Loadable<[FeeType: SwapFee]>> {get}
    
    var payingTokenDriver: Driver<PayingToken> {get}
    
    var errorDriver: Driver<String?> {get}
    
    var isExchangeRateReversedDriver: Driver<Bool> {get}
    
    // Signals
    var useAllBalanceDidTapSignal: Signal<Double?> {get}
    
    // Actions
    func reload()
    func calculateExchangeRateAndFees()
    func navigate(to: SwapToken.NavigatableScene)
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

protocol SwapTokenApiClient {
    func getLamportsPerSignature() -> Single<SolanaSDK.Lamports>
    func getCreatingTokenAccountFee() -> Single<UInt64>
}

extension SolanaSDK: SwapTokenApiClient {}
