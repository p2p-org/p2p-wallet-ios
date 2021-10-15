//
//  OrcaSwapV2.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/10/2021.
//

import Foundation
import RxSwift
import RxCocoa

protocol OrcaSwapV2ViewModelType: WalletDidSelectHandler {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {get}
    var loadingStateDriver: Driver<LoadableState> {get}
    var sourceWalletDriver: Driver<Wallet?> {get}
    var destinationWalletDriver: Driver<Wallet?> {get}
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {get}
    var inputAmountDriver: Driver<Double?> {get}
    var estimatedAmountDriver: Driver<Double?> {get}
    
    func reload()
    func chooseSourceWallet()
    func chooseDestinationWallet()
    func swapSourceAndDestination()
    func useAllBalance()
    func enterInputAmount(_ amount: Double?)
    func enterEstimatedAmount(_ amount: Double?)
}

extension OrcaSwapV2 {
    class ViewModel {
        // MARK: - Dependencies
        @Injected private var analyticsManager: AnalyticsManagerType
        private let orcaSwap: OrcaSwapType
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        private var isSelectingSourceWallet = false // indicate if selecting source wallet or destination wallet
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let loadingStateSubject = BehaviorRelay<LoadableState>(value: .notRequested)
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let tradablePoolsPairsSubject = LoadableRelay<[OrcaSwap.PoolsPair]>(request: .just([]))
        private let bestPoolsPairSubject = BehaviorRelay<OrcaSwap.PoolsPair?>(value: nil)
        private let inputAmountSubject = BehaviorRelay<Double?>(value: nil)
        private let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        
        // MARK: - Initializer
        init(
            orcaSwap: OrcaSwapType,
            initialWallet: Wallet?
        ) {
            self.orcaSwap = orcaSwap
            
            bind(initialWallet: initialWallet)
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
            
            // get tradable pools pair for each token pair
            Observable.combineLatest(
                sourceWalletSubject,
                destinationWalletSubject
            )
                .subscribe(onNext: {[weak self] sourceWallet, destinationWallet in
                    guard let self = self,
                          let sourceWallet = sourceWallet,
                          let destinationWallet = destinationWallet
                    else {
                        self?.tradablePoolsPairsSubject.request = .just([])
                        self?.tradablePoolsPairsSubject.reload()
                        return
                    }
                    
                    self.tradablePoolsPairsSubject.request = self.orcaSwap.getTradablePoolsPairs(
                        fromMint: sourceWallet.token.address,
                        toMint: destinationWallet.token.address
                    )
                    self.tradablePoolsPairsSubject.reload()
                })
                .disposed(by: disposeBag)
            
            // FIXME: - fill input amount and estimated amount after loaded
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
        }
    }
}

extension OrcaSwapV2.ViewModel: OrcaSwapV2ViewModelType {
    var navigationDriver: Driver<OrcaSwapV2.NavigatableScene?> {
        navigationSubject.asDriver()
    }
    
    var loadingStateDriver: Driver<LoadableState> {
        loadingStateSubject.asDriver()
    }
    
    var sourceWalletDriver: Driver<Wallet?> {
        sourceWalletSubject.asDriver()
    }
    
    var destinationWalletDriver: Driver<Wallet?> {
        destinationWalletSubject.asDriver()
    }
    
    var isTokenPairValidDriver: Driver<Loadable<Bool>> {
        tradablePoolsPairsSubject.asDriver()
            .map { value, state, reloadAction in
                (value?.isEmpty == false, state, reloadAction)
            }
    }
    
    var inputAmountDriver: Driver<Double?> {
        inputAmountSubject.asDriver()
    }
    
    var estimatedAmountDriver: Driver<Double?> {
        estimatedAmountSubject.asDriver()
    }
    
    // MARK: - Actions
    func reload() {
        loadingStateSubject.accept(.loading)
        orcaSwap.load()
            .subscribe(onCompleted: { [weak self] in
                self?.loadingStateSubject.accept(.loaded)
            }, onError: {error in
                self.loadingStateSubject.accept(.error(error.readableDescription))
            })
            .disposed(by: disposeBag)
    }
    
    func chooseSourceWallet() {
        isSelectingSourceWallet = true
        navigationSubject.accept(.chooseSourceWallet)
    }
    
    func chooseDestinationWallet() {
        guard let sourceWallet = sourceWalletSubject.value,
              let destinationMints = try? orcaSwap.findPosibleDestinationMints(fromMint: sourceWallet.token.address)
        else {return}
        isSelectingSourceWallet = false
        navigationSubject.accept(.chooseDestinationWallet(validMints: Set(destinationMints), excludedSourceWalletPubkey: sourceWallet.pubkey))
    }
    
    func swapSourceAndDestination() {
        let source = sourceWalletSubject.value
        sourceWalletSubject.accept(destinationWalletSubject.value)
        destinationWalletSubject.accept(source)
    }
    
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }
    
    func useAllBalance() {
        // TODO: - useAllBalance
//        // calculate available balance
//
//        // input
//        enterInputAmount(availableBalance)
    }
    
    func enterInputAmount(_ amount: Double?) {
        inputAmountSubject.accept(amount)
        
        // calculate estimated amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let inputAmount = amount?.toLamport(decimals: sourceDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolsPairForInputAmount(inputAmount, from: poolsPairs),
           let bestEstimatedAmount = bestPoolsPair.getOutputAmount(fromInputAmount: inputAmount)
        {
            bestPoolsPairSubject.accept(bestPoolsPair)
            estimatedAmountSubject.accept(bestEstimatedAmount.convertToBalance(decimals: destinationDecimals))
        }
    }
    
    func enterEstimatedAmount(_ amount: Double?) {
        estimatedAmountSubject.accept(amount)
        
        // calculate input amount
        if let sourceDecimals = sourceWalletSubject.value?.token.decimals,
           let destinationDecimals = destinationWalletSubject.value?.token.decimals,
           let estimatedAmount = amount?.toLamport(decimals: destinationDecimals),
           let poolsPairs = tradablePoolsPairsSubject.value,
           let bestPoolsPair = try? orcaSwap.findBestPoolForEstimatedAmount(estimatedAmount, from: poolsPairs),
           let bestInputAmount = bestPoolsPair.getInputAmount(fromEstimatedAmount: estimatedAmount)
        {
            bestPoolsPairSubject.accept(bestPoolsPair)
            inputAmountSubject.accept(bestInputAmount.convertToBalance(decimals: sourceDecimals))
        }
    }
}
