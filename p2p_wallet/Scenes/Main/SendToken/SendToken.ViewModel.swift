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
    var amountDriver: Driver<Double?> {get}
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
    
    func isTestNet() -> Bool
    
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
        @Injected private var nameService: NameServiceType
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
        private let burnAndReleaseFeeSubject: LoadableRelay<Double>
        
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
            
            self.feeSubject = .init(request: .just(0)) // placeholder
            self.burnAndReleaseFeeSubject = .init(request: renVMBurnAndReleaseService.getFee())
            
            // accept initial values
            if let pubkey = walletPubkey {
                walletSubject.accept(repository.getWallets().first(where: {$0.pubkey == pubkey}))
            } else {
                walletSubject.accept(repository.nativeWallet)
            }
            
            destinationAddressSubject.accept(destinationAddress)
            
            bind()
            reload()
        }
        
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
                            network: .solana,
                            receiveAtLeast: nil
                        )
                    }
                    return nil
                }
                .bind(to: renBTCInfoSubject)
                .disposed(by: disposeBag)
            
            // receive at least
            Observable.combineLatest(
                amountSubject.distinctUntilChanged(),
                burnAndReleaseFeeSubject.valueObservable
            )
                .withLatestFrom(renBTCInfoSubject, resultSelector: {($1, $0.0, $0.1)})
                .subscribe(onNext: {[weak self] info, amount, fee in
                    guard var info = info else {return}
                    var receiveAtLeast = amount
                    if let amount = amount, let fee = fee {
                        receiveAtLeast = amount - fee
                        if receiveAtLeast! < 0 {receiveAtLeast = 0}
                    }
                    info.receiveAtLeast = receiveAtLeast
                    self?.renBTCInfoSubject.accept(info)
                })
                .disposed(by: disposeBag)
            
            // verify
            Observable.combineLatest(
                walletSubject.distinctUntilChanged().asObservable(),
                currencyModeSubject.distinctUntilChanged().asObservable(),
                amountSubject.distinctUntilChanged(),
                feeSubject.valueObservable.distinctUntilChanged(),
                renBTCInfoSubject.distinctUntilChanged()
            )
                .map { [weak self] wallet, currencyMode, amount, fee, renBTCInfo in
                    verifyError(
                        wallet: wallet,
                        nativeWallet: self?.repository.nativeWallet,
                        currencyMode: currencyMode,
                        amount: amount,
                        fee: fee,
                        renBTCInfo: renBTCInfo
                    )
                }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)
            
            // destination address
            Observable.combineLatest(
                destinationAddressSubject.distinctUntilChanged(),
                renBTCInfoSubject
            )
                .do(onNext: { [weak self] _ in
                    self?.addressValidationStatusSubject.accept(.fetching)
                })
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .flatMap {[weak self] address, renBTCInfo -> Single<AddressValidationStatus> in
                    guard let self = self, let address = address, !address.isEmpty else {
                        return .just(.uncheck)
                    }
                    self.addressValidationStatusSubject.accept(.fetching)
                    let request: Single<Bool>
                    if renBTCInfo?.network == .bitcoin {
                        request = .just(false)
                    } else {
                        request = self.apiClient.checkNameOrAccountValidation(nameOrAccount: address, nameService: self.nameService)
                    }
                    return request.map {$0 ? .valid: .invalid}
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
            
            // BTC network
            if wallet.token.address.isRenBTCMint && renBTCInfoSubject.value?.network == .bitcoin
            {
                request = renVMBurnAndReleaseService.burn(
                    recipient: receiver,
                    amount: amount.toLamport(decimals: 8)
                )
            }
            
            // solana network
            else {
                // check address
                var addressRequest = Single<String>.just(receiver)
                if receiver.hasSuffix(.nameServiceDomain) {
                    let name = receiver.replacingOccurrences(of: String.nameServiceDomain, with: "")
                    addressRequest = nameService.getOwner(name)
                        .map {
                            guard let owner = $0?.owner else {
                                throw SolanaSDK.Error.other(L10n.theUsernameIsNotAvailable(receiver))
                            }
                            return owner
                        }
                }
                
                // native solana
                if wallet.isNativeSOL {
                    request = addressRequest
                        .flatMap {[weak self] receiver in
                            guard let self = self else {throw SolanaSDK.Error.unknown}
                            
                            return self.apiClient.sendNativeSOL(
                                to: receiver,
                                amount: lamport,
                                withoutFee: Defaults.useFreeTransaction,
                                isSimulation: false
                            )
                        }
                }
                
                // other tokens
                else {
                    request = addressRequest
                        .flatMap {[weak self] receiver in
                            guard let self = self else {throw SolanaSDK.Error.unknown}
                            
                            return self.apiClient.sendSPLTokens(
                                mintAddress: wallet.mintAddress,
                                decimals: wallet.token.decimals,
                                from: sender,
                                to: receiver,
                                amount: lamport,
                                withoutFee: Defaults.useFreeTransaction,
                                isSimulation: false
                            )
                        }
                }
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
        
        private func reloadFee() {
            feeSubject.request = feeRequest(network: renBTCInfoSubject.value?.network)
            feeSubject.reload()
        }
        
        private func feeRequest(network: SendRenBTCInfo.Network?) -> Single<Double> {
            if network == .bitcoin {
                return .just(0.001571)
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
    
    var amountDriver: Driver<Double?> {
        amountSubject.asDriver()
    }
    
    var availableAmountDriver: Driver<Double?> {
        Driver.combineLatest(
            currentWalletDriver,
            currentCurrencyModeDriver,
            feeDriver
        )
            .map {wallet, currencyMode, fee -> Double? in
                calculateAvailableAmount(
                    wallet: wallet,
                    currencyMode: currencyMode,
                    fee: fee.value
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
        reloadFee()
        burnAndReleaseFeeSubject.reload()
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
        
        // re-calculate fee
        reloadFee()
    }
    
    func isTestNet() -> Bool {
        renVMBurnAndReleaseService.isTestNet()
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
    guard let wallet = wallet else {return nil}
    // all amount
    var availableAmount = wallet.amount ?? 0
    
    // minus fee if wallet is native sol
    if wallet.isNativeSOL == true {
        guard let fee = fee else {return nil}
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
    fee: Double?,
    renBTCInfo: SendToken.SendRenBTCInfo?
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
        if let info = renBTCInfo, info.network == .bitcoin {
            if let receiveAtLeast = info.receiveAtLeast, receiveAtLeast <= 0 {
                return L10n.amountIsTooSmall
            }
        } else if let fee = fee,
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
