//
//  SendViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 01/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import LazySubject

protocol SendTokenAPIClient {
    func getFees() -> Single<SolanaSDK.Fee>
    func checkAccountValidation(account: String) -> Single<Bool>
    func sendSOL(
        to destination: String,
        amount: UInt64,
        withoutFee: Bool,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
    func sendSPLTokens(
        mintAddress: String,
        decimals: SolanaSDK.Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        withoutFee: Bool,
        isSimulation: Bool
    ) -> Single<SolanaSDK.TransactionID>
}

extension SolanaSDK: SendTokenAPIClient {
    func getFees() -> Single<Fee> {
        getFees(commitment: nil)
    }
}

extension SendToken {
    class ViewModel: ViewModelType {
        enum AddressValidationStatus {
            case uncheck
            case fetching
            case valid
            case invalid
            case fetchingError
            case invalidIgnored
        }
        
        // MARK: - Nested type
        struct Input {
            let walletPubkey = PublishSubject<String?>()
            let amount = PublishSubject<Double?>()
            let address = PublishSubject<String?>()
            let currencyMode = PublishSubject<CurrencyMode>()
            let noFundsConfirmation = PublishSubject<Bool>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene>
            let currentWallet: Driver<Wallet?>
            let currencyMode: Driver<CurrencyMode>
            let fee: LazySubject<Double>
            let availableAmount: Driver<Double?>
            let isValid: Driver<Bool>
            let error: Driver<String?>
            let useAllBalanceDidTouch: Driver<Double?>
            let receiverAddress: Driver<String?>
            let addressValidationStatus: Driver<AddressValidationStatus>
        }
        
        // MARK: - Dependencies
        private let repository: WalletsRepository
        private let apiClient: SendTokenAPIClient
        private let authenticationHandler: AuthenticationHandler
        let analyticsManager: AnalyticsManagerType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        private let navigationSubject = PublishSubject<NavigatableScene>()
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        private let addressSubject = BehaviorRelay<String?>(value: nil)
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        private let feeSubject: LazySubject<Double>
        private let availableAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let isValidSubject = BehaviorRelay<Bool>(value: false)
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let useAllBalanceDidTouchSubject = PublishSubject<Double?>()
        private let addressValidationStatusSubject = BehaviorRelay<AddressValidationStatus>(value: .fetching)
        
        // MARK: - Initializer
        init(
            repository: WalletsRepository,
            walletPubkey: String?,
            destinationAddress: String?,
            apiClient: SendTokenAPIClient,
            authenticationHandler: AuthenticationHandler,
            analyticsManager: AnalyticsManagerType
        ) {
            self.repository = repository
            self.apiClient = apiClient
            self.authenticationHandler = authenticationHandler
            self.analyticsManager = analyticsManager
            
            self.feeSubject = LazySubject<Double>(
                request: Defaults.useFreeTransaction ? .just(0) : apiClient.getFees()
                    .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
                    .map {
                        let decimals = repository.solWallet?.token.decimals
                        return $0.convertToBalance(decimals: decimals)
                    }
            )
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: .chooseWallet),
                currentWallet: walletSubject
                    .asDriver(onErrorJustReturn: nil),
                currencyMode: currencyModeSubject
                    .asDriver(onErrorJustReturn: .token),
                fee: feeSubject,
                availableAmount: availableAmountSubject
                    .asDriver(onErrorJustReturn: nil),
                isValid: isValidSubject
                    .asDriver(onErrorJustReturn: false),
                error: errorSubject
                    .asDriver(onErrorJustReturn: nil),
                useAllBalanceDidTouch: useAllBalanceDidTouchSubject
                    .asDriver(onErrorJustReturn: nil),
                receiverAddress: addressSubject
                    .asDriver(onErrorJustReturn: nil),
                addressValidationStatus: addressValidationStatusSubject
                    .asDriver()
            )
            
            bind()
            feeSubject.reload()
            
            input.walletPubkey.onNext(walletPubkey ?? repository.getWallets().first?.pubkey)
            input.address.onNext(destinationAddress)
        }
        
        /// Bind output into input
        private func bind() {
            bindInputToSubjects()
            
            bindSubjectsToSubjects()
        }
        
        private func bindInputToSubjects() {
            // wallet
            input.walletPubkey
                .map {pubkey in
                    self.repository.getWallets().first(where: {$0.pubkey == pubkey})
                }
                .bind(to: walletSubject)
                .disposed(by: disposeBag)
            
            // amount
            input.amount
                .bind(to: amountSubject)
                .disposed(by: disposeBag)
            
            // address
            input.address
                .bind(to: addressSubject)
                .disposed(by: disposeBag)
            
            // currency mode
            input.currencyMode
                .bind(to: currencyModeSubject)
                .disposed(by: disposeBag)
            
            // no funds confirmation
            input.noFundsConfirmation
                .map {isIgnoring -> AddressValidationStatus in
                    if isIgnoring {
                        return .invalidIgnored
                    }
                    return .invalid
                }
                .bind(to: addressValidationStatusSubject)
                .disposed(by: disposeBag)
        }
        
        private func bindSubjectsToSubjects() {
            // detect if price isn't available
            walletSubject.distinctUntilChanged()
                .subscribe(onNext: {[weak self] wallet in
                    if wallet?.priceInCurrentFiat == nil && self?.currencyModeSubject.value == .fiat
                    {
                        self?.currencyModeSubject.accept(.token)
                    }
                })
                .disposed(by: disposeBag)
            
            // available amount
            Observable.combineLatest(
                walletSubject.asObservable(),
                currencyModeSubject.asObservable()
            )
                .map {(wallet, currencyMode) -> Double? in
                    guard let wallet = wallet else {return nil}
                    return Self.calculateAvailableAmount(wallet: wallet, currencyMode: currencyMode)
                }
                .bind(to: availableAmountSubject)
                .disposed(by: disposeBag)
            
            // error subject
            Observable.combineLatest(
                walletSubject.distinctUntilChanged(),
                amountSubject.distinctUntilChanged(),
                addressSubject.distinctUntilChanged(),
                currencyModeSubject.distinctUntilChanged(),
                feeSubject.observable.distinctUntilChanged()
            )
                .map {[weak self] params in
                    self?.verifyError(wallet: params.0, amount: params.1, fee: self?.feeSubject.value)
                }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
            
            // address info
            addressSubject
                .distinctUntilChanged()
                .do(onNext: { [weak self] _ in
                    self?.addressValidationStatusSubject.accept(.fetching)
                })
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .flatMap {[weak self] address -> Single<AddressValidationStatus> in
                    guard let address = address, !address.isEmpty else {
                        return .just(.uncheck)
                    }
                    self?.addressValidationStatusSubject.accept(.fetching)
                    return (self?.apiClient.checkAccountValidation(account: address) ?? .just(false))
                        .map {isValid -> AddressValidationStatus in
                            isValid ? .valid: .invalid
                        }
                        .catchAndReturn(.fetchingError)
                }
                
                .bind(to: addressValidationStatusSubject)
                .disposed(by: disposeBag)
            
            // is valid subject
            let observables: [Observable<Bool>] = [
                errorSubject.map {$0 == nil},
                walletSubject.map {$0 != nil},
                addressSubject.map {$0 != nil && !$0!.isEmpty},
                amountSubject.map {$0 != nil},
                addressValidationStatusSubject.map {$0 == .valid || $0 == .invalidIgnored}
            ]
            
            Observable.combineLatest(observables)
                .map {$0.allSatisfy {$0}}
                .bind(to: isValidSubject)
                .disposed(by: disposeBag)
        }
        
        // MARK: - Actions
        @objc func useAllBalance() {
            let amount = availableAmountSubject.value
            input.amount.onNext(amount)
            if let amount = amount {
                analyticsManager.log(event: .sendAvailableClick(sum: amount))
            }
            useAllBalanceDidTouchSubject.onNext(amount)
        }
        
        @objc func clearDestinationAddress() {
            input.address.onNext(nil)
        }
        
        @objc func chooseWallet() {
            navigationSubject.onNext(.chooseWallet)
        }
        
        @objc func chooseAddress() {
            navigationSubject.onNext(.chooseAddress)
        }
        
        @objc func scanQrCode() {
            analyticsManager.log(event: .sendScanQrClick)
            analyticsManager.log(event: .scanQrOpen(fromPage: "send"))
            navigationSubject.onNext(.scanQrCode)
        }
        
        @objc func showFeeInfo() {
            navigationSubject.onNext(.feeInfo)
        }
        
        @objc func switchCurrencyMode() {
            if walletSubject.value?.priceInCurrentFiat == nil {
                if currencyModeSubject.value == .fiat {
                    currencyModeSubject.accept(.token)
                }
            } else {
                if currencyModeSubject.value == .fiat {
                    currencyModeSubject.accept(.token)
                } else {
                    currencyModeSubject.accept(.fiat)
                }
            }
            
            analyticsManager.log(event: .sendChangeInputMode(selectedValue: currencyModeSubject.value == .token ? "token": "fiat"))
        }
        
        @objc func authenticateAndSend() {
            authenticationHandler.authenticate(
                presentationStyle:
                    .init(
                        isRequired: false,
                        isFullScreen: false,
                        completion: { [weak self] in
                            self?.send()
                        }
                    )
            )
        }
        
        // MARK: - Helpers
        private static func calculateAvailableAmount(
            wallet: Wallet?,
            currencyMode: CurrencyMode
        ) -> Double? {
            switch currencyMode {
            case .token:
                return wallet?.amount
            case .fiat:
                return wallet?.amountInCurrentFiat
            }
        }
        
        /// Verify current context
        /// - Returns: Error string, nil if no error appear
        private func verifyError(
            wallet: Wallet?,
            amount: Double?,
            fee: Double?
        ) -> String? {
            // Verify wallet
            guard wallet != nil else {
                return L10n.youMustSelectAWalletToSend
            }
            
            // Verify amount if it has been entered
            if let amount = amount {
                // Amount is not valid
                if amount <= 0 {
                    return L10n.amountIsNotValid
                }
                
                // Verify with fee
                if let fee = fee,
                   let solAmount = repository.solWallet?.amount,
                   fee > solAmount
                {
                    return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
                }
                
                // Verify amount
                let amountToCompare = self.availableAmountSubject.value
                if amount.rounded(decimals: Int(wallet?.token.decimals ?? 0)) > amountToCompare?.rounded(decimals: Int(wallet?.token.decimals ?? 0))
                {
                    return L10n.insufficientFunds
                }
            }
            
            return nil
        }
        
        private func send() {
            // verify
            guard errorSubject.value == nil,
                  let wallet = walletSubject.value,
                  let sender = wallet.pubkey,
                  let receiver = addressSubject.value,
                  var amount = amountSubject.value
            else {
                return
            }
            
            // get decimal
            let decimals = wallet.token.decimals
            
            // convert
            if currencyModeSubject.value == .fiat,
               let price = wallet.priceInCurrentFiat,
               price > 0
            {
                amount = amount / price
            }
            
            // form request
            // prepare amount
            let lamport = amount.toLamport(decimals: decimals)
            
            // define token
            var request: Single<String>!
            let isSendingSOL = wallet.token.symbol == "SOL"
            if isSendingSOL {
                // SOLANA
                request = apiClient.sendSOL(
                    to: receiver,
                    amount: lamport,
                    withoutFee: Defaults.useFreeTransaction,
                    isSimulation: false
                )
            } else {
                // other tokens
                request = apiClient.sendSPLTokens(
                    mintAddress: wallet.mintAddress,
                    decimals: wallet.token.decimals,
                    from: sender,
                    to: receiver,
                    amount: lamport,
                    withoutFee: Defaults.useFreeTransaction,
                    isSimulation: false
                )
            }
            
            // log
            analyticsManager.log(
                event: .sendSendClick(
                    tokenTicker: wallet.token.symbol,
                    sum: lamport.convertToBalance(decimals: wallet.token.decimals)
                )
            )
            
            // show processing scene
            navigationSubject.onNext(
                .processTransaction(
                    request: request.map {$0 as ProcessTransactionResponseType},
                    transactionType: .send(
                        from: wallet,
                        to: receiver,
                        lamport: lamport,
                        feeInLamports: feeSubject.value?.toLamport(decimals: wallet.token.decimals) ?? 0
                    )
                )
            )
        }
    }
}
