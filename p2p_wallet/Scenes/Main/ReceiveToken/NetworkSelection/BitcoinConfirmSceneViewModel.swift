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
            self.receiveBitcoinViewModel = receiveBitcoinViewModel
            if let wallet = (walletRepository.getWallets().first { $0.amount > 0 }) {
                payingWalletRelay.accept(wallet)
            }
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

            return rentBTCService.createAssociatedTokenAccount(
                payingFeeAddress: payingAddress,
                payingFeeMintAddress: payingWallet.mintAddress
            )
                .flatMap { [weak self] id -> Single<Any?> in
                    guard let self = self else {
                        return .error(NSError(
                            domain: "ReceiveToken.BitcoinCreateAccountScene.ViewModel",
                            code: 1
                        ))
                    }
                    return self.solanaSDK.waitForConfirmation(signature: id).andThen(.just(nil))
                }
                .do(onError: { [weak self] error in
                    self?.notification.showInAppNotification(.error(error))
                    self?.isLoadingRelay.accept(false)
                })
                .asCompletable()
        }

        func selectWallet(wallet: Wallet) {
            payingWalletRelay.accept(wallet)
        }

        var feeAmount: Driver<String> {
            payingWalletRelay
                .flatMap { [weak self] wallet -> Single<String> in
                    guard
                        let self = self,
                        let wallet = wallet,
                        wallet.pubkey != nil
                    else {
                        return .just("")
                    }

                    return self
                        .rentBTCService
                        .getCreationFee(payingFeeMintAddress: wallet.mintAddress)
                        .map { lamports in
                            "\(lamports.convertToBalance(decimals: wallet.token.decimals)) \(wallet.token.symbol)"
                        }
                }
                .asDriver { _ in
                    .just("")
                }
        }
    }
}
