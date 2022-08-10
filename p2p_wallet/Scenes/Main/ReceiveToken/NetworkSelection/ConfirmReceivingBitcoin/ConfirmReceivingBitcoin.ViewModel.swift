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

        @Published private var navigatableScene: NavigatableScene?
        @Published private var isLoading = true
        @Published private var error: String?
        @Published private var accountStatus: RenBTCAccountStatus?
        @Published private var payableWallets = [Wallet]()

        @Published private var payingWallet: Wallet?
        @Published private var totalFee: Double?
        @Published private var feeInFiat: Double?

        // MARK: - Initializer

        init() {
            reload()
            bind()
        }

        // MARK: - Methods

        func reload() {
            isLoading = true
            error = nil
            accountStatus = nil
            payableWallets = []
            payingWallet = nil

            Task {
                do {
                    try await renBTCStatusService.load()
                    let payableWallets = try await renBTCStatusService.getPayableWallets()

                    error = nil
                    accountStatus
                        = !payableWallets.isEmpty ? .payingWalletAvailable : .topUpRequired
                    payableWallets = payableWallets
                    payingWallet = payableWallets.first
                } catch {
                    error = error.readableDescription
                    accountStatus = nil
                    payableWallets = []
                    payingWallet = nil
                }
                isLoading = false
            }
        }

        private func bind() {
            $payingWallet
                .asyncMap { [weak self] wallet -> Double? in
                    guard let self = self, let wallet = wallet else { return nil }
                    let fee = try await self.renBTCStatusService
                        .getCreationFee(payingFeeMintAddress: wallet.mintAddress)
                    return fee.convertToBalance(decimals: wallet.token.decimals)
                }
                .replaceError(with: nil)
                .assign(to: \.totalFee, on: self)
                .store(in: &subscriptions)

            $totalFee
                .map { [weak self] fee -> Double? in
                    guard let fee = fee, let symbol = self?.payingWallet?.token.symbol,
                          let price = self?.pricesService.currentPrice(for: symbol)?.value else { return nil }
                    return fee * price
                }
                .assign(to: \.feeInFiat, on: self)
                .store(in: &subscriptions)
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var solanaPubkey: String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var isLoadingDriver: AnyPublisher<Bool, Never> {
        $isLoading.eraseToAnyPublisher()
    }

    var errorDriver: AnyPublisher<String?, Never> {
        $error.eraseToAnyPublisher()
    }

    var accountStatusDriver: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> {
        $accountStatus.eraseToAnyPublisher()
    }

    var payingWalletDriver: AnyPublisher<Wallet?, Never> {
        $payingWallet.eraseToAnyPublisher()
    }

    var totalFeeDriver: AnyPublisher<Double?, Never> {
        $totalFee.eraseToAnyPublisher()
    }

    var feeInFiatDriver: AnyPublisher<Double?, Never> {
        $feeInFiat.eraseToAnyPublisher()
    }

    var navigationDriver: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?) {
        navigatableScene = scene
    }

    func walletDidSelect(_ wallet: Wallet) {
        payingWallet = wallet
    }

    func navigateToChoosingWallet() {
        navigate(to: .chooseWallet(selectedWallet: payingWallet,
                                   payableWallets: payableWallets))
    }

    func createRenBTC() {
        guard let mintAddress = payingWallet?.mintAddress,
              let address = payingWallet?.pubkey
        else { return }

        isLoading = true
        error = nil

        Task {
            do {
                try await renBTCStatusService.createAccount(
                    payingFeeAddress: address,
                    payingFeeMintAddress: mintAddress
                )
                error = nil

                await MainActor.run { [weak self] in
                    self?.completion?()
                }
            } catch {
                self.error = error.readableDescription
            }

            isLoading = false
        }
    }

    func dismissAndTopUp() {
        topUpCompletion?()
    }
}
