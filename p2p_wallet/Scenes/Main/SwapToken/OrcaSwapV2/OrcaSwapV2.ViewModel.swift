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
    
    func reload()
    func chooseSourceWallet()
    func chooseDestinationWallet()
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
    
    func walletDidSelect(_ wallet: Wallet) {
        if isSelectingSourceWallet {
            analyticsManager.log(event: .swapTokenASelectClick(tokenTicker: wallet.token.symbol))
            sourceWalletSubject.accept(wallet)
        } else {
            analyticsManager.log(event: .swapTokenBSelectClick(tokenTicker: wallet.token.symbol))
            destinationWalletSubject.accept(wallet)
        }
    }
}
