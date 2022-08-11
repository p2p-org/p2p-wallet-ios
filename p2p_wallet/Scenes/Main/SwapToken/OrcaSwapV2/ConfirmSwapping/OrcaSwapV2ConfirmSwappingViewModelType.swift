//
//  OrcaSwapV2ConfirmSwappingViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Combine
import Foundation
import SolanaSwift

protocol OrcaSwapV2ConfirmSwappingViewModelType: DetailFeesViewModelType {
    var sourceWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var destinationWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var inputAmountPublisher: AnyPublisher<Double?, Never> { get }
    var estimatedAmountPublisher: AnyPublisher<Double?, Never> { get }
    var minimumReceiveAmountPublisher: AnyPublisher<Double?, Never> { get }
    var exchangeRatesPublisher: AnyPublisher<Double?, Never> { get }
    var slippagePublisher: AnyPublisher<Double, Never> { get }

    func isBannerForceClosed() -> Bool

    func closeBanner()
    func authenticateAndSwap()
    func showFeesInfo(_ info: PayingFee.Info)
}

extension OrcaSwapV2ConfirmSwappingViewModelType {
    var inputAmountStringPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            sourceWalletPublisher,
            inputAmountPublisher
        )
            .map { wallet, amount in
                amount.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
            }
            .eraseToAnyPublisher()
    }

    var inputAmountInFiatStringPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            sourceWalletPublisher,
            inputAmountPublisher
        )
            .map { wallet, amount in
                Defaults.fiat.symbol + (amount * wallet?.priceInCurrentFiat).toString(maximumFractionDigits: 2)
            }
            .eraseToAnyPublisher()
    }

    var estimatedAmountStringPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            destinationWalletPublisher,
            estimatedAmountPublisher
        )
            .map { wallet, amount in
                amount.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
            }
            .eraseToAnyPublisher()
    }

    var receiveAtLeastStringPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            destinationWalletPublisher,
            minimumReceiveAmountPublisher
        )
            .map { wallet, amount in
                amount.toString(maximumFractionDigits: 9) + " " + (wallet?.token.symbol ?? "")
            }
            .eraseToAnyPublisher()
    }

    var receiveAtLeastInFiatStringPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            destinationWalletPublisher,
            minimumReceiveAmountPublisher
        )
            .map { wallet, amount in
                Defaults.fiat.symbol + (amount * wallet?.priceInCurrentFiat).toString(maximumFractionDigits: 2)
            }
            .eraseToAnyPublisher()
    }
}
