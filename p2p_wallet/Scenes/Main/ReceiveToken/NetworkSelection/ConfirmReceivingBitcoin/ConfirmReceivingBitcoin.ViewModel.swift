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
    var navigatableScenePublisher: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> { get }
    var isLoadingPublisher: AnyPublisher<Bool, Never> { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }
    var accountStatusPublisher: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> { get }
    var payingWalletPublisher: AnyPublisher<Wallet?, Never> { get }
    var totalFeePublisher: AnyPublisher<Double?, Never> { get }
    var feeInFiatPublisher: AnyPublisher<Double?, Never> { get }

    func reload()
    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?)
    func navigateToChoosingWallet()
    func createRenBTC()
    func dismissAndTopUp()
}

extension ConfirmReceivingBitcoinViewModelType {
    var feeInTextPublisher: AnyPublisher<String?, Never> {
        Publishers.CombineLatest(
            totalFeePublisher,
            payingWalletPublisher
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
    class ViewModel: BaseViewModel {
        // MARK: - Dependencies

        @Injected private var renBTCStatusService: RenBTCStatusServiceType
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        @Injected private var userWalletManager: UserWalletManager

        // MARK: - Properties

        var completion: (() -> Void)?
        var topUpCompletion: (() -> Void)?

        // MARK: - Subject

        @MainActor @Published private var navigatableScene: NavigatableScene?
        @MainActor @Published private var isLoading = true
        @MainActor @Published private var error: String?
        @MainActor @Published private var accountStatus: RenBTCAccountStatus?
        @MainActor @Published private var payableWallets = [Wallet]()

        @MainActor @Published private var payingWallet: Wallet?
        @MainActor @Published private var totalFee: Double?
        @MainActor @Published private var feeInFiat: Double?

        // MARK: - Initializer

        override init() {
            super.init()
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
                    try await renBTCServiceDidLoad()
                } catch {
                    renBTCServiceDidFailToLoadWithError(error)
                }
                await MainActor.run {
                    isLoading = false
                }
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
                .receive(on: RunLoop.main)
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
        
        private func renBTCServiceDidLoad() async throws {
            error = nil

            // CASE 1: User logged in using web3auth
            if userWalletManager.isUserLoggedInUsingWeb3 {
                accountStatus = .freeCreationAvailable
                payableWallets = []
                payingWallet = nil
            }

            // CASE 2: User logged in using seed phrase
            else {
                let payableWallets = try await renBTCStatusService.getPayableWallets()
                accountStatus = !payableWallets.isEmpty ? .payingWalletAvailable : .topUpRequired
                self.payableWallets = payableWallets
                payingWallet = payableWallets.first
            }
        }
        
        private func renBTCServiceDidFailToLoadWithError(_ error: Error) {
            self.error = error.readableDescription
            accountStatus = nil
            payableWallets = []
            payingWallet = nil
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var solanaPubkey: String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $isLoading.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String?, Never> {
        $error.eraseToAnyPublisher()
    }

    var accountStatusPublisher: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> {
        $accountStatus.eraseToAnyPublisher()
    }

    var payingWalletPublisher: AnyPublisher<Wallet?, Never> {
        $payingWallet.eraseToAnyPublisher()
    }

    var totalFeePublisher: AnyPublisher<Double?, Never> {
        $totalFee.eraseToAnyPublisher()
    }

    var feeInFiatPublisher: AnyPublisher<Double?, Never> {
        $feeInFiat.eraseToAnyPublisher()
    }

    var navigatableScenePublisher: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> {
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
        isLoading = true
        error = nil

        Task {
            do {
                try await renBTCStatusService.createAccount(
                    payingFeeAddress: payingWallet?.pubkey,
                    payingFeeMintAddress: payingWallet?.mintAddress
                )
                error = nil

                await MainActor.run { [weak self] in
                    self?.completion?()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = error.readableDescription
                }
            }
            await MainActor.run { [weak self] in
                self?.isLoading = false
            }
        }
    }

    func dismissAndTopUp() {
        topUpCompletion?()
    }
}
