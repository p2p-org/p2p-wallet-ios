//
//  SwapSettingsInfoViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 02.03.2023.
//

import Combine
import Foundation

final class SwapSettingsInfoViewModel {
    let image: UIImage
    let title: String
    let subtitle: String
    let buttonTitle: String

    @Published private(set) var fees = [Fee]()
    
    // MARK: - Output
    
    private let closeSubject = PassthroughSubject<Void, Never>()
    var close: AnyPublisher<Void, Never> { closeSubject.eraseToAnyPublisher() }
    
    // MARK: - Init
    
    init(strategy: Strategy) {
        switch strategy {
        case .enjoyFreeTransaction:
            image = .startThree
            title = L10n.enjoyFreeTransactions + "!"
            subtitle = L10n.withKeyAppAllTransactionsYouMakeOnTheSolanaNetworkAreFree
            buttonTitle = L10n.gotIt + "👍"
        case .accountCreationFee:
            image = .accountCreationFeeHand
            title = L10n.accountCreationFee
            subtitle = L10n.whenYouTradeTheTokenForTheFirstTimeSolanaChargesAOneTimeFeeForCreatingAnAccount
            buttonTitle = L10n.gotIt + "👍"
        case .minimumReceived:
            image = .minimumReceived
            title = L10n.minimumReceived
            subtitle = L10n.TheMinimumAmountYouWillReceive.ifThePriceSlipsAnyFurtherYourTransactionWillRevert
            buttonTitle = L10n.done + "👍"
        case let .liquidityFee(fees):
            image = .liquidityFee
            title = L10n.liquidityFee
            subtitle = L10n.aFeePaidToTheLiquidityProviders
            buttonTitle = L10n.okay + "👍"
            self.fees = fees
        }
    }
    
    func closeClicked() {
        closeSubject.send()
    }
}

// MARK: - Strategy

extension SwapSettingsInfoViewModel {
    enum Strategy {
        case enjoyFreeTransaction
        case accountCreationFee
        case minimumReceived
        case liquidityFee(fees: [Fee])
    }
}

// MARK: - Fee Model

extension SwapSettingsInfoViewModel {
    struct Fee {
        let title: String
        let subtitle: String
        var amount: String?
    }
}
