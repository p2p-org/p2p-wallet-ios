//
//  BitcoinConfirmSceneViewModel.swift
//  p2p_wallet
//
//  Created by Ivan on 11.04.2022.
//  Copyright © 2022 Ivan Babich. All rights reserved.
//

import RxCocoa
import RxSwift

protocol BitcoinCreateAccountViewModelType {
    var isLoadingDriver: Driver<Bool> { get }
    var payingWallet: Driver<Wallet?> { get }
    var feeAmount: Driver<String> { get }
    var feeAmountInFiat: Driver<String> { get }

    func create() -> Completable
    func selectWallet(wallet: Wallet)
}

extension ReceiveToken.BitcoinConfirmScene {
    final class ViewModel: BitcoinCreateAccountViewModelType {
        @Injected var solanaSDK: SolanaSDK
        @Injected var walletRepository: WalletsRepository
        @Injected var rentBTCService: RentBTC.Service
        @Injected var notification: NotificationsServiceType
        private let receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType

        private let payingWalletRelay: BehaviorRelay<Wallet?> = BehaviorRelay(value: nil)
        private let isLoadingRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)

        init(receiveBitcoinViewModel: ReceiveTokenBitcoinViewModelType) {
            debugPrint("Init ReceiveToken.BitcoinConfirmScene.ViewModel")

            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            if let wallet = (walletRepository.getWallets().first { $0.amount > 0 }) {
                payingWalletRelay.accept(wallet)
            }
        }

        deinit {
            debugPrint("Deinit ReceiveToken.BitcoinConfirmScene.ViewModel")
        }

        // MARK: - Implementation BitcoinCreateAccountViewModelType

        var isLoadingDriver: Driver<Bool> { isLoadingRelay.asDriver() }
        var payingWallet: Driver<Wallet?> { payingWalletRelay.asDriver() }

        func create() -> Completable {
            isLoadingRelay.accept(true)
            guard
                let payingWallet = payingWalletRelay.value,
                let payingAddress = payingWallet.pubkey
            else {
                isLoadingRelay.accept(false)
                return .error(NSError(
                    domain: "ReceiveToken.BitcoinCreateAccountScene.ViewModel.NotSelected",
                    code: 1
                ))
            }

            return Completable
                .asyncThrowing { [weak self] in
                    guard let self = self else { throw ReceiveToken.Error.unknown }
                    let signature = try await self.rentBTCService.createAccount(
                        payingFeeAddress: payingAddress,
                        payingFeeMintAddress: payingWallet.mintAddress
                    )
                    try await self.solanaSDK.waitForConfirmation(signature: signature).value
                }
                .do(onError: { [weak self] error in
                    self?.isLoadingRelay.accept(false)
                    DispatchQueue.main.async {
                        self?.notification.showInAppNotification(.error(error))
                    }
                })
        }

        func selectWallet(wallet: Wallet) {
            payingWalletRelay.accept(wallet)
        }

        private var rawFeeAmount: Observable<UInt64> {
            payingWalletRelay
                .flatMap { [weak self] wallet -> Single<UInt64> in
                    guard
                        let self = self,
                        let wallet = wallet,
                        wallet.pubkey != nil
                    else {
                        return .just(0)
                    }

                    return Single
                        .asyncThrowing { [weak self] () -> SolanaSDK.Lamports in
                            guard let self = self else { return 0 }
                            return try await self.rentBTCService
                                .getCreationFee(payingFeeMintAddress: wallet.mintAddress)
                        }
                }
                .asObservable()
        }

        var feeAmount: Driver<String> {
            rawFeeAmount
                .map { [weak self] lamports in
                    guard
                        let self = self,
                        let wallet = self.payingWalletRelay.value,
                        wallet.pubkey != nil
                    else {
                        return "0"
                    }

                    return "\(lamports.convertToBalance(decimals: wallet.token.decimals)) \(wallet.token.symbol)"
                }
                .asDriver()
        }

        var feeAmountInFiat: Driver<String> {
            rawFeeAmount
                .map { [weak self] amount in
                    guard
                        let self = self,
                        let wallet = self.payingWalletRelay.value
                    else {
                        return ""
                    }

                    return "\((wallet.priceInCurrentFiat ?? 0) * Double(amount))$"
                }
                .asDriver()
        }
    }
}
