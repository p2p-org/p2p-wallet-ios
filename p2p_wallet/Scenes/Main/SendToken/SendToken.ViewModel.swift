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

protocol SendTokenViewModelType: WalletDidSelectHandler {
    var navigatableSceneDriver: Driver<SendToken.NavigatableScene?> {get}
    var currentWalletDriver: Driver<Wallet?> {get}
    var currentCurrencyModeDriver: Driver<SendToken.CurrencyMode> {get}
    var useAllBalanceSignal: Signal<Double?> {get}
    var feeDriver: Driver<Loadable<Double>> {get}
    var availableAmountDriver: Driver<Double?> {get}
    var isValidDriver: Driver<Bool> {get}
    var errorDriver: Driver<String?> {get}
    var receiverAddressDriver: Driver<String?> {get}
    var addressValidationStatusDriver: Driver<SendToken.AddressValidationStatus> {get}
    var renBTCInfoDriver: Driver<SendToken.SendRenBTCInfo?> {get}
    
    func reload()
    func navigate(to scene: SendToken.NavigatableScene)
    func navigateToSelectBTCNetwork()
    func chooseWallet(_ wallet: Wallet)
    func enterAmount(_ amount: Double?)
    func switchCurrencyMode()
    func useAllBalance()
    
    func enterWalletAddress(_ address: String?)
    func clearDestinationAddress()
    func ignoreEmptyBalance(_ isIgnored: Bool)
    
    func changeRenBTCNetwork(to network: SendToken.SendRenBTCInfo.Network)
    
    func authenticateAndSend()
}

extension SendTokenViewModelType {
    func walletDidSelect(_ wallet: Wallet) {
        chooseWallet(wallet)
    }
}

extension SendToken {
    class ViewModel {
        // MARK: - Dependencies
        private let repository: WalletsRepository
        private let apiClient: SendTokenAPIClient
        @Injected private var authenticationHandler: AuthenticationHandler
        @Injected private var analyticsManager: AnalyticsManagerType
        private let renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let walletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let currencyModeSubject = BehaviorRelay<CurrencyMode>(value: .token)
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        private let useAllBalanceSubject = PublishRelay<Double?>()
        private let destinationAddressSubject = BehaviorRelay<String?>(value: nil)
        private let feeSubject: LoadableRelay<Double>
        private let errorSubject = BehaviorRelay<String?>(value: nil)
        private let addressValidationStatusSubject = BehaviorRelay<AddressValidationStatus>(value: .fetching)
        private let renBTCInfoSubject = BehaviorRelay<SendRenBTCInfo?>(value: nil)
        
        // MARK: - Initializer
        init(
            repository: WalletsRepository,
            walletPubkey: String?,
            destinationAddress: String?,
            apiClient: SendTokenAPIClient,
            renVMBurnAndReleaseService: RenVMBurnAndReleaseServiceType
        ) {
            self.repository = repository
            self.apiClient = apiClient
            self.renVMBurnAndReleaseService = renVMBurnAndReleaseService
            
            self.feeSubject = .init(request: .just(0))
            
            bind()
            reload()
            
            // accept initial values
            if let pubkey = walletPubkey {
                walletSubject.accept(repository.getWallets().first(where: {$0.pubkey == pubkey}))
            } else {
                walletSubject.accept(repository.nativeWallet)
            }
            
            destinationAddressSubject.accept(destinationAddress)
        }
        
        /// Bind output into input
        private func bind() {
            // detect if price isn't available
            walletSubject.distinctUntilChanged()
                .filter {$0 != nil && $0?.priceInCurrentFiat == nil}
                .map {_ in CurrencyMode.token}
                .bind(to: currencyModeSubject)
                .disposed(by: disposeBag)
            
            // detect renBTC
            walletSubject.distinctUntilChanged()
                .map {wallet -> SendRenBTCInfo? in
                    if wallet?.token.address.isRenBTCMint == true {
                        return .init(
                            network: .bitcoin,
                            receiveAtLeast: nil
                        )
                    }
                    return nil
                }
                .bind(to: renBTCInfoSubject)
                .disposed(by: disposeBag)
            
            renBTCInfoSubject
                .map {$0?.network}
                .distinctUntilChanged()
                .subscribe(onNext: {[weak self] network in
                    guard let self = self else {return}
                    self.feeSubject.request = self.feeRequest(network: network)
                    self.feeSubject.reload()
                })
                .disposed(by: disposeBag)
            
            // verify
            Observable.combineLatest(
                walletSubject.distinctUntilChanged().asObservable(),
                currencyModeSubject.distinctUntilChanged().asObservable(),
                amountSubject.distinctUntilChanged(),
                feeSubject.valueObservable.distinctUntilChanged()
            )
                .map { [weak self] wallet, currencyMode, amount, fee in
                    verifyError(
                        wallet: wallet,
                        nativeWallet: self?.repository.nativeWallet,
                        currencyMode: currencyMode,
                        amount: amount,
                        fee: fee
                    )
                }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
            
            // destination address
            destinationAddressSubject
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
        }
        
        private func send() {
            // verify
            guard errorSubject.value == nil,
                  let wallet = walletSubject.value,
                  let sender = wallet.pubkey,
                  let receiver = destinationAddressSubject.value,
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
            
            // renBTC
            if wallet.token.address.isRenBTCMint && renBTCInfoSubject.value?.network == .bitcoin
            {
                request = renVMBurnAndReleaseService.burn(
                    recipient: receiver,
                    amount: amount.toLamport(decimals: 8)
                )
            }
            
            // native solana
            else if wallet.isNativeSOL {
                request = apiClient.sendNativeSOL(
                    to: receiver,
                    amount: lamport,
                    withoutFee: Defaults.useFreeTransaction,
                    isSimulation: false
                )
            }
            
            // other tokens
            else {
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
            navigationSubject.accept(
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
        
        private func feeRequest(network: SendRenBTCInfo.Network?) -> Single<Double> {
            if network == .bitcoin {
                return renVMBurnAndReleaseService.getFee()
            }
            return Defaults.useFreeTransaction ? .just(0) : apiClient.getFees()
                .map {$0.feeCalculator?.lamportsPerSignature ?? 0}
                .map { [weak self] in
                    let decimals = self?.repository.nativeWallet?.token.decimals
                    return $0.convertToBalance(decimals: decimals)
                }
        }
    }
}

extension SendToken.ViewModel: SendTokenViewModelType {
    var navigatableSceneDriver: Driver<SendToken.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var currentWalletDriver: Driver<Wallet?> {
        walletSubject.asDriver()
    }
    
    var currentCurrencyModeDriver: Driver<SendToken.CurrencyMode> {
        currencyModeSubject.asDriver()
    }
    
    var useAllBalanceSignal: Signal<Double?> {
        useAllBalanceSubject.asSignal()
    }
    
    var feeDriver: Driver<Loadable<Double>> {
        feeSubject.asDriver()
    }
    
    var availableAmountDriver: Driver<Double?> {
        Driver.combineLatest(
            currentWalletDriver,
            currentCurrencyModeDriver,
            feeDriver
        )
            .map {wallet, currencyMode, fee -> Double? in
                guard let wallet = wallet,
                      fee.state == .loaded,
                      let feeInSOL = fee.value
                else {return nil}
                return calculateAvailableAmount(
                    wallet: wallet,
                    currencyMode: currencyMode,
                    fee: feeInSOL
                )
            }
    }
    
    var isValidDriver: Driver<Bool> {
        Driver.combineLatest([
            errorDriver.map {$0 == nil},
            currentWalletDriver.map {$0 != nil},
            receiverAddressDriver.map {$0 != nil && !$0!.isEmpty},
            amountSubject.asDriver().map {$0 != nil},
            addressValidationStatusDriver.map {$0 == .valid || $0 == .invalidIgnored}
        ])
            .map {$0.allSatisfy {$0}}
    }
    
    var errorDriver: Driver<String?> {
        errorSubject.asDriver()
    }
    
    var receiverAddressDriver: Driver<String?> {
        destinationAddressSubject.asDriver()
    }
    
    var addressValidationStatusDriver: Driver<SendToken.AddressValidationStatus> {
        addressValidationStatusSubject.asDriver()
    }
    
    var renBTCInfoDriver: Driver<SendToken.SendRenBTCInfo?> {
        renBTCInfoSubject.asDriver()
    }
    
    // MARK: - Actions
    func reload() {
        feeSubject.reload()
    }
    
    func navigate(to scene: SendToken.NavigatableScene) {
        navigationSubject.accept(scene)
    }
    
    func navigateToSelectBTCNetwork() {
        guard let selectedNetwork = renBTCInfoSubject.value?.network else {return}
        navigationSubject.accept(.chooseBTCNetwork(selectedNetwork: selectedNetwork))
    }
    
    func chooseWallet(_ wallet: Wallet) {
        analyticsManager.log(
            event: .sendSelectTokenClick(tokenTicker: wallet.token.symbol)
        )
        walletSubject.accept(wallet)
    }
    
    func enterAmount(_ amount: Double?) {
        amountSubject.accept(amount)
    }
    
    func switchCurrencyMode() {
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
    
    func useAllBalance() {
        let amount = calculateAvailableAmount(
            wallet: walletSubject.value,
            currencyMode: currencyModeSubject.value,
            fee: feeSubject.value
        )
        if let amount = amount {
            analyticsManager.log(event: .sendAvailableClick(sum: amount))
        }
        useAllBalanceSubject.accept(amount)
        amountSubject.accept(amount)
    }
    
    func enterWalletAddress(_ address: String?) {
        destinationAddressSubject.accept(address)
    }
    
    func clearDestinationAddress() {
        destinationAddressSubject.accept(nil)
    }
    
    func ignoreEmptyBalance(_ isIgnored: Bool) {
        if isIgnored {
            addressValidationStatusSubject.accept(.invalidIgnored)
        } else {
            addressValidationStatusSubject.accept(.invalid)
        }
    }
    
    func changeRenBTCNetwork(to network: SendToken.SendRenBTCInfo.Network) {
        guard var info = renBTCInfoSubject.value else {return}
        info.network = network
        renBTCInfoSubject.accept(info)
    }
    
    func authenticateAndSend() {
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
}

// MARK: - Helpers
private func calculateAvailableAmount(
    wallet: Wallet?,
    currencyMode: SendToken.CurrencyMode,
    fee: Double?
) -> Double? {
    guard let wallet = wallet,
          let fee = fee
    else {return nil}
    // all amount
    var availableAmount = wallet.amount ?? 0
    
    // minus fee if wallet is native sol
    if wallet.isNativeSOL == true {
        availableAmount = availableAmount - fee
    }
    
    // renBTC fee
    else if wallet.token.address.isRenBTCMint {
        availableAmount = availableAmount - fee
    }
    
    // convert to fiat in fiat mode
    if currencyMode == .fiat {
        availableAmount = availableAmount * wallet.priceInCurrentFiat
    }
    
    // return
    return availableAmount > 0 ? availableAmount: 0
}

/// Verify current context
/// - Returns: Error string, nil if no error appear
private func verifyError(
    wallet: Wallet?,
    nativeWallet: Wallet?,
    currencyMode: SendToken.CurrencyMode,
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
           let solAmount = nativeWallet?.amount,
           fee > solAmount
        {
            return L10n.yourAccountDoesNotHaveEnoughSOLToCoverFee
        }
        
        // Verify amount
        let amountToCompare = calculateAvailableAmount(wallet: wallet, currencyMode: currencyMode, fee: fee)
        if amount.rounded(decimals: Int(wallet?.token.decimals ?? 0)) > amountToCompare?.rounded(decimals: Int(wallet?.token.decimals ?? 0))
        {
            return L10n.insufficientFunds
        }
    }
    
    return nil
}

private extension String {
    var isRenBTCMint: Bool {
        self == SolanaSDK.PublicKey.renBTCMint.base58EncodedString ||
            self == SolanaSDK.PublicKey.renBTCMintDevnet.base58EncodedString
    }
}
