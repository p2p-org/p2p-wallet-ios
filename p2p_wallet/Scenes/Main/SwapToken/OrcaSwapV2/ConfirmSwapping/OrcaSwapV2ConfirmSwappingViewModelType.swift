//
//  OrcaSwapV2ConfirmSwappingViewModelType.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2021.
//

import Foundation
import RxCocoa
import SolanaSwift

protocol OrcaSwapV2ConfirmSwappingViewModelType: DetailFeesViewModelType {
    var sourceWalletDriver: Driver<Wallet?> { get }
    var destinationWalletDriver: Driver<Wallet?> { get }
    var inputAmountDriver: Driver<Double?> { get }
    var estimatedAmountDriver: Driver<Double?> { get }
    var minimumReceiveAmountDriver: Driver<Double?> { get }
    var exchangeRatesDriver: Driver<Double?> { get }
    var slippageDriver: Driver<Double> { get }

    func isBannerForceClosed() -> Bool

    func closeBanner()
    func authenticateAndSwap()
    func showFeesInfo(_ info: PayingFee.Info)
}

extension OrcaSwapV2ConfirmSwappingViewModelType {
    var inputAmountStringDriver: Driver<String?> {
        Driver.combineLatest(
            sourceWalletDriver,
            inputAmountDriver
        )
            .map { wallet, amount in
                amount.orZero.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
            }
    }

    var inputAmountInFiatStringDriver: Driver<String?> {
        Driver.combineLatest(
            sourceWalletDriver,
            inputAmountDriver
        )
            .map { wallet, amount in
                Defaults.fiat.symbol + (amount * wallet?.priceInCurrentFiat).toString(maximumFractionDigits: 2)
            }
    }

    var estimatedAmountStringDriver: Driver<String?> {
        Driver.combineLatest(
            destinationWalletDriver,
            estimatedAmountDriver
        )
            .map { wallet, amount in
                amount.orZero.toString(maximumFractionDigits: 9) + " " + wallet?.token.symbol
            }
    }

    var receiveAtLeastStringDriver: Driver<String?> {
        Driver.combineLatest(
            destinationWalletDriver,
            minimumReceiveAmountDriver
        )
            .map { wallet, amount in
                amount.orZero.toString(maximumFractionDigits: 9) + " " + (wallet?.token.symbol ?? "")
            }
    }

    var receiveAtLeastInFiatStringDriver: Driver<String?> {
        Driver.combineLatest(
            destinationWalletDriver,
            minimumReceiveAmountDriver
        )
            .map { wallet, amount in
                Defaults.fiat.symbol + (amount * wallet?.priceInCurrentFiat).toString(maximumFractionDigits: 2)
            }
    }
}
