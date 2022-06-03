//
//  ConfirmReceivingBitcoin.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol ConfirmReceivingBitcoinViewModelType: WalletDidSelectHandler {
    var solanaPubkey: String? { get }
    var navigationDriver: Driver<ConfirmReceivingBitcoin.NavigatableScene?> { get }
    var isLoadingDriver: Driver<Bool> { get }
    var errorDriver: Driver<String?> { get }
    var accountStatusDriver: Driver<ConfirmReceivingBitcoin.RenBTCAccountStatus?> { get }
    var payingWalletDriver: Driver<Wallet?> { get }
    var totalFeeDriver: Driver<Double?> { get }
    var feeInFiatDriver: Driver<Double?> { get }

    func reload()
    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?)
    func navigateToChoosingWallet()
    func createRenBTC()
    func dismissAndTopUp()
}

extension ConfirmReceivingBitcoinViewModelType {
    var feeInTextDriver: Driver<String?> {
        Driver.combineLatest(
            totalFeeDriver,
            payingWalletDriver
        )
            .map { fee, wallet in
                guard let fee = fee, let wallet = wallet else {
                    return nil
                }
                return fee.toString(maximumFractionDigits: 9) + " " + wallet.token.symbol
            }
    }
}

extension ConfirmReceivingBitcoin {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var renBTCStatusService: RenBTCStatusServiceType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private let disposeBag = DisposeBag()
        var completion: (() -> Void)?
        var topUpCompletion: (() -> Void)?

        // MARK: - Subject

        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let isLoadingSubject = BehaviorRelay<Bool>(value: true)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let accountStatusSubject = BehaviorRelay<RenBTCAccountStatus?>(value: nil)
        private let payableWalletsSubject = BehaviorRelay<[Wallet]>(value: [])

        private let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let totalFeeSubject = BehaviorRelay<Double?>(value: nil)
        private let feeInFiatSubject = BehaviorRelay<Double?>(value: nil)

        // MARK: - Initializer

        init() {
            reload()
            bind()
        }

        // MARK: - Methods

        func reload() {
            isLoadingSubject.accept(true)
            errorSubject.accept(nil)
            accountStatusSubject.accept(nil)
            payableWalletsSubject.accept([])
            payingWalletSubject.accept(nil)

            Task {
                do {
                    try await renBTCStatusService.load()
                    let payableWallets = try await renBTCStatusService.getPayableWallets()

                    errorSubject.accept(nil)
                    accountStatusSubject
                        .accept(!payableWallets.isEmpty ? .payingWalletAvailable : .topUpRequired)
                    payableWalletsSubject.accept(payableWallets)
                    payingWalletSubject.accept(payableWallets.first)
                } catch {
                    errorSubject.accept(error.readableDescription)
                    accountStatusSubject.accept(nil)
                    payableWalletsSubject.accept([])
                    payingWalletSubject.accept(nil)
                }
                isLoadingSubject.accept(false)
            }
        }

        private func bind() {
            payingWalletSubject
                .flatMapLatest { wallet -> Single<Double?> in
                    Single.async { [weak self] in
                        guard let self = self, let wallet = wallet else { return nil }
                        let fee = try await self.renBTCStatusService
                            .getCreationFee(payingFeeMintAddress: wallet.mintAddress)
                        return fee.convertToBalance(decimals: wallet.token.decimals)
                    }
                }
                .catchAndReturn(nil)
                .bind(to: totalFeeSubject)
                .disposed(by: disposeBag)

            totalFeeSubject
                .map { [weak self] fee -> Double? in
                    guard let fee = fee, let symbol = self?.payingWalletSubject.value?.token.symbol,
                          let price = self?.pricesService.currentPrice(for: symbol)?.value else { return nil }
                    return fee * price
                }
                .bind(to: feeInFiatSubject)
                .disposed(by: disposeBag)
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var solanaPubkey: String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingSubject.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }

    var accountStatusDriver: Driver<ConfirmReceivingBitcoin.RenBTCAccountStatus?> {
        accountStatusSubject.asDriver()
    }

    var payingWalletDriver: Driver<Wallet?> {
        payingWalletSubject.asDriver()
    }

    var totalFeeDriver: Driver<Double?> {
        totalFeeSubject.asDriver()
    }

    var feeInFiatDriver: Driver<Double?> {
        feeInFiatSubject.asDriver()
    }

    var navigationDriver: Driver<ConfirmReceivingBitcoin.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?) {
        navigationSubject.accept(scene)
    }

    func walletDidSelect(_ wallet: Wallet) {
        payingWalletSubject.accept(wallet)
    }

    func navigateToChoosingWallet() {
        navigate(to: .chooseWallet(selectedWallet: payingWalletSubject.value,
                                   payableWallets: payableWalletsSubject.value))
    }

    func createRenBTC() {
        guard let mintAddress = payingWalletSubject.value?.mintAddress,
              let address = payingWalletSubject.value?.pubkey
        else { return }

        isLoadingSubject.accept(true)
        errorSubject.accept(nil)

        Task {
            do {
                try await renBTCStatusService.createAccount(
                    payingFeeAddress: address,
                    payingFeeMintAddress: mintAddress
                )
                errorSubject.accept(nil)

                await MainActor.run { [weak self] in
                    self?.completion?()
                }
            } catch {
                errorSubject.accept(error.readableDescription)
            }

            isLoadingSubject.accept(false)
        }
    }

    func dismissAndTopUp() {
        topUpCompletion?()
    }
}
