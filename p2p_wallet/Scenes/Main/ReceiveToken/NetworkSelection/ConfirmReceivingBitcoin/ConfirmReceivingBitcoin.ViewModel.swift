//
//  ConfirmReceivingBitcoin.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import Combine
import Foundation
import Resolver
import SolanaSwift

protocol ConfirmReceivingBitcoinViewModelType: WalletDidSelectHandler {
    var solanaPubkey: String? { get }
    var navigationDriver: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> { get }
    var isLoadingDriver: AnyPublisher<Bool, Never> { get }
    var errorDriver: AnyPublisher<String?, Never> { get }
    var accountStatusDriver: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> { get }
    var payingWalletDriver: AnyPublisher<Wallet?, Never> { get }
    var totalFeeDriver: AnyPublisher<Double?, Never> { get }
    var feeInFiatDriver: AnyPublisher<Double?, Never> { get }

    func reload()
    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?)
    func navigateToChoosingWallet()
    func createRenBTC()
    func dismissAndTopUp()
}

extension ConfirmReceivingBitcoinViewModelType {
    var feeInTextDriver: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            totalFeeDriver,
            payingWalletDriver
        )
            .map { fee, wallet in
                guard let fee = fee, let wallet = wallet else {
                    return nil
                }
                return fee.toString(maximumFractionDigits: 9) + " " + wallet.token.symbol
            }
            .eraseToAnyPublisher()
    }
}

extension ConfirmReceivingBitcoin {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected private var renBTCStatusService: RenBTCStatusServiceType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository

        // MARK: - Properties

        private var subscriptions = [AnyCancellable]()
        var completion: (() -> Void)?
        var topUpCompletion: (() -> Void)?

        // MARK: - Subject

        @Published private var navigationSubject: NavigatableScene?
        @Published private var isLoadingSubject = true
        @Published private var errorSubject: String?
        @Published private var accountStatusSubject: RenBTCAccountStatus?
        @Published private var payableWalletsSubject = [Wallet]()

        @Published private var payingWalletSubject: Wallet?
        @Published private var totalFeeSubject: Double?
        @Published private var feeInFiatSubject: Double?

        // MARK: - Initializer

        init() {
            reload()
            bind()
        }

        // MARK: - Methods

        func reload() {
            isLoadingSubject = true
            errorSubject = nil
            accountStatusSubject = nil
            payableWalletsSubject = []
            payingWalletSubject = nil

            Task {
                do {
                    try await renBTCStatusService.load()
                    let payableWallets = try await renBTCStatusService.getPayableWallets()

                    errorSubject = nil
                    accountStatusSubject
                        = !payableWallets.isEmpty ? .payingWalletAvailable : .topUpRequired
                    payableWalletsSubject = payableWallets
                    payingWalletSubject = payableWallets.first
                } catch {
                    errorSubject = error.readableDescription
                    accountStatusSubject = nil
                    payableWalletsSubject = []
                    payingWalletSubject = nil
                }
                isLoadingSubject = false
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

    var isLoadingDriver: AnyPublisher<Bool, Never> {
        $isLoadingSubject.eraseToAnyPublisher()
    }

    var errorDriver: AnyPublisher<String?, Never> {
        $errorSubject.eraseToAnyPublisher()
    }

    var accountStatusDriver: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> {
        $accountStatusSubject.eraseToAnyPublisher()
    }

    var payingWalletDriver: AnyPublisher<Wallet?, Never> {
        $payingWalletSubject.eraseToAnyPublisher()
    }

    var totalFeeDriver: AnyPublisher<Double?, Never> {
        $totalFeeSubject.eraseToAnyPublisher()
    }

    var feeInFiatDriver: AnyPublisher<Double?, Never> {
        $feeInFiatSubject.eraseToAnyPublisher()
    }

    var navigationDriver: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> {
        $navigationSubject.eraseToAnyPublisher()
    }

    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?) {
        navigationSubject = scene
    }

    func walletDidSelect(_ wallet: Wallet) {
        payingWalletSubject = wallet
    }

    func navigateToChoosingWallet() {
        navigate(to: .chooseWallet(selectedWallet: payingWalletSubject,
                                   payableWallets: payableWalletsSubject))
    }

    func createRenBTC() {
        guard let mintAddress = payingWalletSubject?.mintAddress,
              let address = payingWalletSubject?.pubkey
        else { return }

        isLoadingSubject = true
        errorSubject = nil

        Task {
            do {
                try await renBTCStatusService.createAccount(
                    payingFeeAddress: address,
                    payingFeeMintAddress: mintAddress
                )
                errorSubject = nil

                await MainActor.run { [weak self] in
                    self?.completion?()
                }
            } catch {
                errorSubject = error.readableDescription
            }

            isLoadingSubject = false
        }
    }

    func dismissAndTopUp() {
        topUpCompletion?()
    }
}
