//
//  SendToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/11/2021.
//

import AnalyticsManager
import FeeRelayerSwift
import Foundation
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift

protocol SendTokenViewModelType: SendTokenRecipientAndNetworkHandler, SendTokenTokenAndAmountHandler,
    SendTokenSelectNetworkViewModelType
{
    var navigationSubject: BehaviorRelay<SendToken.NavigatableScene?> { get }
    var relayMethod: SendTokenRelayMethod { get }
    var canGoBack: Bool { get }
    var navigationDriver: Driver<SendToken.NavigatableScene?> { get }
    var loadingStateDriver: Driver<LoadableState> { get }
    var maxWasClicked: Bool { get set }

    func getPrice(for symbol: String) -> Double
    func getPrices(for symbols: [String]) -> [String: Double]
    func getSelectableNetworks() -> [SendToken.Network]
    func getSelectedRecipient() -> SendToken.Recipient?
    func getSelectedNetwork() -> SendToken.Network
    func getSelectedAmount() -> Double?
    func getFreeTransactionFeeLimit() -> Single<UsageStatus>

    func reload()
    func navigate(to scene: SendToken.NavigatableScene)
    func chooseWallet(_ wallet: Wallet)
    func cleanAllFields()

    func shouldShowConfirmAlert() -> Bool
    func closeConfirmAlert()

    func authenticateAndSend()
}

extension SendToken {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var authenticationHandler: AuthenticationHandlerType
        @Injected private var analyticsManager: AnalyticsManager
        @Injected private var pricesService: PricesServiceType
        @Injected private var walletsRepository: WalletsRepository
        let sendService: SendServiceType

        // MARK: - Properties

        let disposeBag = DisposeBag()
        let relayMethod: SendTokenRelayMethod
        let canGoBack: Bool
        var maxWasClicked = false

        // MARK: - Subject

        let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        let amountSubject = BehaviorRelay<Double?>(value: nil)
        let recipientSubject = BehaviorRelay<Recipient?>(value: nil)
        let networkSubject = BehaviorRelay<Network>(value: .solana)
        let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        let payingWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let feeInfoSubject = LoadableRelay<SendToken.FeeInfo>(
            request: .just(
                .init(feeAmount: .zero, feeAmountInSOL: .zero, hasAvailableWalletToPayFee: nil)
            )
        )

        // MARK: - Initializers

        init(
            walletPubkey: String?,
            relayMethod: SendTokenRelayMethod,
            canGoBack: Bool = true
        ) {
            self.relayMethod = relayMethod
            self.canGoBack = canGoBack
            sendService = Resolver.resolve(args: relayMethod)

            // accept initial values
            if let pubkey = walletPubkey,
               let selectableWallet = walletsRepository.getWallets()
                   .first(where: { $0.pubkey == pubkey }) ?? walletsRepository.nativeWallet
            {
                walletSubject.accept(selectableWallet)
            } else {
                walletSubject.accept(walletsRepository.nativeWallet)
            }

            bind()
            reload()
        }

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func bind() {
            bindFees(walletSubject: walletSubject)

            // update wallet after sending
            walletsRepository.dataObservable
                .skip(1)
                .withLatestFrom(walletSubject.asObservable(), resultSelector: { ($0, $1) })
                .subscribe(onNext: { [weak self] wallets, myWallet in
                    guard let self = self else { return }
                    if let wallet = wallets?.first(where: { $0.pubkey == myWallet?.pubkey }),
                       wallet.lamports != myWallet?.lamports
                    {
                        self.walletSubject.accept(wallet)
                    }
                })
                .disposed(by: disposeBag)
        }

        func reload() {
            loadingStateSubject.accept(.loading)

            Completable.zip(
                Completable.async { try await self.sendService.load() },
                walletsRepository.stateObservable
                    .filter { $0 == .loaded }
                    .take(1)
                    .asSingle()
                    .asCompletable()
            )
                .subscribe(onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.loadingStateSubject.accept(.loaded)
                    if self.walletSubject.value == nil {
                        self.walletSubject.accept(self.walletsRepository.getWallets().first(where: { $0.isNativeSOL }))
                    }
                    if let payingWallet = self.walletsRepository.getWallets()
                        .first(where: { $0.mintAddress == Defaults.payingTokenMint })
                    {
                        self.payingWalletSubject.accept(payingWallet)
                    }
                }, onError: { [weak self] error in
                    self?.loadingStateSubject.accept(.error(error.readableDescription))
                })
                .disposed(by: disposeBag)
        }

        private func send() {
            guard
                let wallet = walletSubject.value,
                var amount = amountSubject.value,
                let receiver = recipientSubject.value
            else { return }

            // modify amount if using source wallet as paying wallet
            if let totalFee = feeInfoSubject.value?.feeAmount,
               totalFee.total > 0,
               payingWalletSubject.value?.pubkey == wallet.pubkey
            {
                let feeAmount = totalFee.total.convertToBalance(decimals: payingWalletSubject.value?.token.decimals)
                if amount + feeAmount > wallet.amount {
                    amount -= feeAmount
                }
            }

            let network = networkSubject.value

            analyticsManager.log(
                event: AmplitudeEvent.sendSendClick(
                    tokenTicker: wallet.token.symbol,
                    sum: amount
                )
            )

            let amountInFiat = (amount * wallet.priceInCurrentFiat.orZero).toString(maximumFractionDigits: 2)

            var feeToken: String?
            if let value = feeInfoSubject.value, value.hasAvailableWalletToPayFee == true,
               let payingWallet = payingWalletSubject.value
            {
                if value.feeAmount.total > 0 {
                    feeToken = payingWallet.token.symbol
                }
            }

            analyticsManager.log(event: AmplitudeEvent.sendConfirmButtonPressed(
                sendNetwork: network.rawValue.firstUppercased(),
                sendCurrency: wallet.token.symbol,
                sendSum: "\(amount)",
                sendMAX: maxWasClicked,
                sendUSD: amountInFiat,
                sendFree: feeInfoSubject.value?.feeAmount.transaction == 0,
                sendUsername: receiver.name != nil,
                sendAccountFeeToken: feeToken == nil ? nil : feeToken ?? ""
            ))

            navigationSubject.accept(
                .processTransaction(
                    ProcessTransaction.SendTransaction(
                        sendService: sendService,
                        network: network,
                        sender: wallet,
                        receiver: receiver,
                        authority: walletsRepository.nativeWallet?.pubkey,
                        amount: amount.toLamport(decimals: wallet.token.decimals),
                        payingFeeWallet: payingWalletSubject.value,
                        feeInSOL: feeInfoSubject.value?.feeAmountInSOL.total ?? 0,
                        feeInToken: feeInfoSubject.value?.feeAmount,
                        isSimulation: false
                    )
                )
            )
        }
    }
}

extension SendToken.ViewModel: SendTokenViewModelType {
    var navigationDriver: Driver<SendToken.NavigatableScene?> {
        navigationSubject.asDriver()
    }

    var loadingStateDriver: Driver<LoadableState> {
        loadingStateSubject.asDriver()
    }

    func getSelectedWallet() -> Wallet? {
        walletSubject.value
    }

    func getPrice(for symbol: String) -> Double {
        pricesService.currentPrice(for: symbol)?.value ?? 0
    }

    func getPrices(for symbols: [String]) -> [String: Double] {
        var dict = [String: Double]()
        for symbol in symbols {
            dict[symbol] = getPrice(for: symbol)
        }
        return dict
    }

    func getSendService() -> SendServiceType {
        sendService
    }

    func getFreeTransactionFeeLimit() -> Single<UsageStatus> {
        Single.async { try await self.sendService.getFreeTransactionFeeLimit() }
    }

    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }

    func navigateToChooseRecipientAndNetworkWithPreSelectedNetwork(_ network: SendToken.Network) {
        recipientSubject.accept(nil)
        navigationSubject.accept(.chooseRecipientAndNetwork(
            showAfterConfirmation: true,
            preSelectedNetwork: network,
            maxWasClicked: false
        ))
    }

    func chooseWallet(_ wallet: Wallet) {
        analyticsManager.log(
            event: AmplitudeEvent.sendSelectTokenClick(tokenTicker: wallet.token.symbol)
        )
        walletSubject.accept(wallet)

        if !wallet.token.isRenBTC, networkSubject.value == .bitcoin {
            selectNetwork(.solana)
        }
    }

    func cleanAllFields() {
        amountSubject.accept(nil)
        recipientSubject.accept(nil)
    }

    func shouldShowConfirmAlert() -> Bool {
        Defaults.shouldShowConfirmAlertOnSend
    }

    func closeConfirmAlert() {
        Defaults.shouldShowConfirmAlertOnSend = false
    }

    func authenticateAndSend() {
        authenticationHandler.authenticate(
            presentationStyle:
            .init(
                completion: { [weak self] _ in
                    self?.send()
                }
            )
        )
    }
}
