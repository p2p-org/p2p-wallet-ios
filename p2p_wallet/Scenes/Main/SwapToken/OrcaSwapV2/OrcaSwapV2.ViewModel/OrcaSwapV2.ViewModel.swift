//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension OrcaSwapV2 {
    class ViewModel {
        // MARK: - Dependencies
        @Injected var authenticationHandler: AuthenticationHandlerType
        @Injected var analyticsManager: AnalyticsManagerType
        @Injected var feeService: FeeServiceType
        @Injected var orcaSwap: OrcaSwapType
        @Injected var walletsRepository: WalletsRepository
        
        // MARK: - Properties
        let disposeBag = DisposeBag()
        var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        var transactionTokensName: String?

        // MARK: - Subject
        let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        let tradablePoolsPairsSubject = LoadableRelay<[OrcaSwap.PoolsPair]>(request: .just([]))
        let bestPoolsPairSubject = BehaviorRelay<OrcaSwap.PoolsPair?>(value: nil)
        let inputAmountSubject = BehaviorRelay<Double?>(value: nil)
        let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        let feesSubject = LoadableRelay<[PayingFee]>(request: .just([]))
        let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        let payingTokenSubject = BehaviorRelay<PayingToken>(value: .nativeSOL) // FIXME
        let errorSubject = BehaviorRelay<VerificationError?>(value: nil)
        let showHideDetailsButtonTapSubject = PublishRelay<Void>()
        let isShowingDetailsSubject = BehaviorRelay<Bool>(value: false)

        // MARK: - setter
        init(
            initialWallet: Wallet?
        ) {
            reload()
            bind(initialWallet: initialWallet ?? walletsRepository.nativeWallet)
        }
        
        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }
        
        func bind(initialWallet: Wallet?) {
            // wait until loaded and choose initial wallet
            if let initialWallet = initialWallet {
                loadingStateSubject
                    .take(until: {$0 == .loaded})
                    .take(1)
                    .subscribe(onNext: {[weak self] _ in
                        self?.sourceWalletSubject.accept(initialWallet)
                    })
                    .disposed(by: disposeBag)
            }
            
            // update wallet after swapping
            walletsRepository.dataObservable
                .skip(1)
                .subscribe(onNext: {[weak self] wallets in
                    if self?.sourceWalletSubject.value?.pubkey != nil,
                       let wallet = wallets?.first(where: {$0.pubkey == self?.sourceWalletSubject.value?.pubkey})
                    {
                        self?.sourceWalletSubject.accept(wallet)
                    }
                    
                    if self?.destinationWalletSubject.value?.pubkey != nil,
                        let wallet = wallets?.first(where: {$0.pubkey == self?.destinationWalletSubject.value?.pubkey})
                    {
                        self?.destinationWalletSubject.accept(wallet)
                    }
                })
                .disposed(by: disposeBag)
            
            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: {[weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = .just([])
                        self?.tradablePoolsPairsSubject.reload()
                        self?.fixPayingToken()
                        return
                    }
                    
                    self.tradablePoolsPairsSubject.request = self.orcaSwap.getTradablePoolsPairs(
                        fromMint: sourceWallet.token.address,
                        toMint: destinationWallet.token.address
                    )
                    self.tradablePoolsPairsSubject.reload()
                    self.fixPayingToken()
                })
                .disposed(by: disposeBag)
            
            // Fill input amount and estimated amount after loaded
            tradablePoolsPairsSubject.stateObservable
                .distinctUntilChanged()
                .filter {$0 == .loaded}
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else {return}
                    if let inputAmount = self.inputAmountSubject.value {
                        self.enterInputAmount(inputAmount)
                    } else if let estimatedAmount = self.estimatedAmountSubject.value {
                        self.enterEstimatedAmount(estimatedAmount)
                    }
                })
                .disposed(by: disposeBag)
            
            // fees
            Observable.combineLatest(
                bestPoolsPairSubject,
                inputAmountSubject,
                slippageSubject
            )
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: {[weak self] _ in
                    guard let self = self else {return}
                    self.feesSubject.request = self.feesRequest()
                    self.feesSubject.reload()
                })
                .disposed(by: disposeBag)
            
            // Error
            Observable.combineLatest(
                loadingStateSubject,
                sourceWalletSubject,
                destinationWalletSubject,
                tradablePoolsPairsSubject.stateObservable,
                bestPoolsPairSubject,
                feesSubject.valueObservable,
                slippageSubject,
                payingTokenSubject
            )
                .map {[weak self] _ in self?.verify() }
                .bind(to: errorSubject)
                .disposed(by: disposeBag)

            showHideDetailsButtonTapSubject
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }

                    self.isShowingDetailsSubject.accept(!self.isShowingDetailsSubject.value)
                })
                .disposed(by: disposeBag)

            Observable.combineLatest(
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] source, destination in
                    var symbols = [String]()
                    if let source = source { symbols.append(source.token.symbol) }
                    if let destination = destination { symbols.append(destination.token.symbol) }
                    self?.transactionTokensName = symbols.isEmpty ? nil: symbols.joined(separator: "+")
                })
                .disposed(by: disposeBag)
        }
        
        func authenticateAndSwap() {
            authenticationHandler.authenticate(
                presentationStyle:
                    .init(
                        isRequired: false,
                        isFullScreen: false,
                        completion: { [weak self] in
                            self?.swap()
                        }
                    )
            )
        }
        
        func swap() {
            guard verify() == nil else {return}
            
            let sourceWallet = sourceWalletSubject.value!
            let destinationWallet = destinationWalletSubject.value!
            let bestPoolsPair = bestPoolsPairSubject.value!
            let inputAmount = inputAmountSubject.value!
            let estimatedAmount = estimatedAmountSubject.value!
            
            // log
            analyticsManager.log(
                event: .swapSwapClick(
                    tokenA: sourceWallet.token.symbol,
                    tokenB: destinationWallet.token.symbol,
                    sumA: inputAmount,
                    sumB: estimatedAmount
                )
            )
            
            // form request
            let request = orcaSwap.swap(
                fromWalletPubkey: sourceWallet.pubkey!,
                toWalletPubkey: destinationWallet.pubkey,
                bestPoolsPair: bestPoolsPair,
                amount: inputAmount,
                slippage: slippageSubject.value,
                isSimulation: false
            )
                .map {$0 as ProcessTransactionResponseType}
            
            // show processing scene
            navigationSubject.accept(
                .processTransaction(
                    request: request,
                    transactionType: .orcaSwap(
                        from: sourceWallet,
                        to: destinationWallet,
                        inputAmount: inputAmount.toLamport(decimals: sourceWallet.token.decimals),
                        estimatedAmount: estimatedAmount.toLamport(decimals: destinationWallet.token.decimals),
                        fees: feesSubject.value?.filter {$0.type != .liquidityProviderFee} ?? []
                    )
                )
            )
        }
    }
}

// MARK: - Helpers
extension OrcaSwapV2.ViewModel {
    func fixPayingToken() {
        // TODO: - Later
        var payingToken = Defaults.payingToken

        // Force using native sol when source or destination is nativeSOL
        if sourceWalletSubject.value?.isNativeSOL == true ||
            destinationWalletSubject.value?.isNativeSOL == true // FIXME: - Fee relayer will support case where destination is native sol
        {
            payingToken = .nativeSOL
        }

        payingTokenSubject.accept(payingToken)
    }
    
    /// Verify error in current context IN ORDER
    /// - Returns: String or nil if no error
    func verify() -> OrcaSwapV2.VerificationError? {
        // loading state
        if loadingStateSubject.value != .loaded {
            return .swappingIsNotAvailable
        }
        
        // source wallet
        guard let sourceWallet = sourceWalletSubject.value else {
            return .sourceWalletIsEmpty
        }
        
        // destination wallet
        guard let destinationWallet = destinationWalletSubject.value else {
            return .destinationWalletIsEmpty
        }
        
        // prevent swap the same token
        if sourceWallet.token.address == destinationWallet.token.address {
            return .canNotSwapToItSelf
        }
        
        // pools pairs
        if tradablePoolsPairsSubject.state != .loaded {
            return .tradablePoolsPairsNotLoaded
        }
        
        if tradablePoolsPairsSubject.value == nil ||
            tradablePoolsPairsSubject.value?.isEmpty == true
        {
            return .tradingPairNotSupported
        }
        
        // inputAmount
        guard let inputAmount = inputAmountSubject.value else {
            return .inputAmountIsEmpty
        }
        
        if inputAmount.rounded(decimals: sourceWallet.token.decimals) <= 0 {
            return .inputAmountIsNotValid
        }
        
        if inputAmount > calculateAvailableAmount() {
            return .insufficientFunds
        }
        
        // estimated amount
        guard let estimatedAmount = estimatedAmountSubject.value else {
            return .estimatedAmountIsNotValid
        }
        
        if estimatedAmount.rounded(decimals: destinationWallet.token.decimals) <= 0 {
            return .estimatedAmountIsNotValid
        }
        
        // best pools pairs
        if bestPoolsPairSubject.value == nil {
            return .bestPoolsPairsIsEmpty
        }
        
        // fees
        if feesSubject.state.isError {
            return .couldNotCalculatingFees
        }
        
        guard feesSubject.state == .loaded else {
            return .feesIsBeingCalculated
        }
        
        // paying with SOL
        if payingTokenSubject.value == .nativeSOL {
            guard let wallet = walletsRepository.nativeWallet else {
                return .nativeWalletNotFound
            }
            
            let feeInSOL = feesSubject.value?.transactionFees(of: "SOL") ?? 0
            
            if feeInSOL > (wallet.lamports ?? 0) {
                return .notEnoughSOLToCoverFees
            }
        }
        
        // paying with SPL token
        else {
            // TODO: - fee compensation
            //                if feeCompensationPool == nil {
            //                    return L10n.feeCompensationPoolNotFound
            //                }
            let feeInToken = feesSubject.value?.transactionFees(of: sourceWallet.token.symbol) ?? 0
            if feeInToken > (sourceWallet.lamports ?? 0) {
                return .notEnoughBalanceToCoverFees
            }
        }
        
        // slippage
        if !isSlippageValid() {
            return .slippageIsNotValid
        }
        
        return nil
    }
    
    func calculateAvailableAmount() -> Double? {
        guard let sourceWallet = sourceWalletSubject.value,
              let fees = feesSubject.value?.transactionFees(of: sourceWallet.token.symbol)
        else {
            return sourceWalletSubject.value?.amount
        }

        // paying with native wallet
        if payingTokenSubject.value == .nativeSOL && !sourceWallet.isNativeSOL {
            return sourceWallet.amount
        }
        // paying with wallet itself
        else {
            let availableAmount = (sourceWallet.amount ?? 0) - fees.convertToBalance(decimals: sourceWallet.token.decimals)
            return availableAmount > 0 ? availableAmount: 0
        }
    }
    
    private func isSlippageValid() -> Bool {
        slippageSubject.value <= .maxSlippage && slippageSubject.value > 0
    }
    
    private func feesRequest() -> Single<[PayingFee]> {
        Single.create { [weak self] observer in
            guard let self = self else {
                observer(.success([]))
                return Disposables.create()
            }
            
            guard let sourceWallet = self.sourceWalletSubject.value,
                  let sourceWalletPubkey = sourceWallet.pubkey,
                  let lamportsPerSignature = self.feeService.lamportsPerSignature,
                  let minRenExempt = self.feeService.minimumBalanceForRenExemption
            else {
                observer(.success([]))
                return Disposables.create()
            }
            
            let destinationWallet = self.destinationWalletSubject.value
            let bestPoolsPair = self.bestPoolsPairSubject.value
            let inputAmount = self.inputAmountSubject.value
            let myWalletsMints = self.walletsRepository.getWallets().compactMap {$0.token.address}
            let slippage = self.slippageSubject.value
            
            guard let fees = try? self.orcaSwap.getFees(
                myWalletsMints: myWalletsMints,
                fromWalletPubkey: sourceWalletPubkey,
                toWalletPubkey: destinationWallet?.pubkey,
                bestPoolsPair: bestPoolsPair,
                inputAmount: inputAmount,
                slippage: slippage,
                lamportsPerSignature: lamportsPerSignature,
                minRentExempt: minRenExempt
            ) else {
                observer(.success([]))
                return Disposables.create()
            }
            
            var allFees = [PayingFee]()
            
            if let destinationWallet = destinationWallet {
                if fees.liquidityProviderFees.count == 1 {
                    allFees.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: fees.liquidityProviderFees.first!,
                            token: destinationWallet.token
                        )
                    )
                } else if fees.liquidityProviderFees.count == 2 {
                    if let intermediaryTokenName = bestPoolsPair?[0].tokenBName, let decimals = bestPoolsPair?[0].getTokenBDecimals() {
                        allFees.append(
                            .init(
                                type: .liquidityProviderFee,
                                lamports: fees.liquidityProviderFees.first!,
                                token: .unsupported(mint: nil, decimals: decimals, symbol: intermediaryTokenName)
                            )
                        )
                    }
                    
                    allFees.append(
                        .init(
                            type: .liquidityProviderFee,
                            lamports: fees.liquidityProviderFees.last!,
                            token: destinationWallet.token
                        )
                    )
                }
            }

            if let creationFee = fees.accountCreationFee {
                allFees.append(
                    .init(
                        type: .accountCreationFee,
                        lamports: creationFee,
                        token: .nativeSolana
                    )
                )
            }
            
            allFees.append(
                .init(
                    type: .transactionFee,
                    lamports: fees.transactionFees,
                    token: .nativeSolana
                )
            )

            observer(.success(allFees))
            return Disposables.create()
        }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    }
}
