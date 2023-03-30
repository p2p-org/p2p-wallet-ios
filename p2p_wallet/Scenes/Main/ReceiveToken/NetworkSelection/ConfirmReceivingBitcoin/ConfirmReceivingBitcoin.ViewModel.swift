//
//  ConfirmReceivingBitcoin.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/04/2022.
//

import AnalyticsManager
import Foundation
import Resolver
import Combine
import SolanaSwift

protocol ConfirmReceivingBitcoinViewModelType: WalletDidSelectHandler {
    var solanaPubkey: String? { get }
    var navigationPublisher: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> { get }
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
            .receive(on: DispatchQueue.main)
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
        @Injected private var userWalletManager: UserWalletManager
        @Injected private var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private var subscriptions = Set<AnyCancellable>()
        var completion: (() -> Void)?
        var topUpCompletion: (() -> Void)?
        var fetchFeeTask: Task<Void, Error>?

        // MARK: - Subject

        @Published private var navigation: NavigatableScene?
        @Published private var isLoading: Bool = true
        @Published private var error: String?
        @Published private var accountStatus: RenBTCAccountStatus?
        @Published private var payableWallets: [Wallet] = []

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

                } catch {
                    self.error = error.readableDescription
                    accountStatus = nil
                    payableWallets = []
                    payingWallet = nil
                }
                isLoading = false
            }
        }

        private func bind() {
            $payingWallet
                .sink(receiveValue: { [weak self] wallet in
                    self?.getTotalFee(wallet: wallet)
                })
                .store(in: &subscriptions)

            $totalFee
                .map { [weak self] fee -> Double? in
                    guard let fee = fee, let mint = self?.payingWallet?.token.address,
                          let price = self?.pricesService.currentPrice(mint: mint)?.value else { return nil }
                    return fee * price
                }
                .assign(to: \.feeInFiat, on: self)
                .store(in: &subscriptions)
        }
        
        private func getTotalFee(wallet: Wallet?) {
            // assign nil
            totalFee = nil
            
            guard let wallet else { return }
            
            // cancel previous task
            fetchFeeTask?.cancel()
            fetchFeeTask = nil
            
            // assign task
            fetchFeeTask = Task { [weak self] in
                guard let self else { return }
                let fee = try await self.renBTCStatusService
                    .getCreationFee(payingFeeMintAddress: wallet.mintAddress)
                let feeInFiat = fee.convertToBalance(decimals: wallet.token.decimals)
                try Task.checkCancellation()
                self.totalFee = feeInFiat
            }
        }
    }
}

extension ConfirmReceivingBitcoin.ViewModel: ConfirmReceivingBitcoinViewModelType {
    var solanaPubkey: String? {
        walletsRepository.nativeWallet?.pubkey
    }

    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        $isLoading.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String?, Never> {
        $error.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var accountStatusPublisher: AnyPublisher<ConfirmReceivingBitcoin.RenBTCAccountStatus?, Never> {
        $accountStatus.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var payingWalletPublisher: AnyPublisher<Wallet?, Never> {
        $payingWallet.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var totalFeePublisher: AnyPublisher<Double?, Never> {
        $totalFee.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var feeInFiatPublisher: AnyPublisher<Double?, Never> {
        $feeInFiat.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var navigationPublisher: AnyPublisher<ConfirmReceivingBitcoin.NavigatableScene?, Never> {
        $navigation.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func navigate(to scene: ConfirmReceivingBitcoin.NavigatableScene?) {
        navigation = scene
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
                analyticsManager.log(event: .renbtcCreation(result: "success"))

                await MainActor.run { [weak self] in
                    self?.completion?()
                }
            } catch {
                self.error = error.readableDescription
                analyticsManager.log(event: .renbtcCreation(result: "fail"))
            }

            isLoading = false
        }
    }

    func dismissAndTopUp() {
        topUpCompletion?()
    }
}
