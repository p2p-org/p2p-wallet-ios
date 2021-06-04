//
//  SwapToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import RxSwift
import RxCocoa
import LazySubject

protocol SwapTokenAPIClient {
    func getSwapPools() -> Single<[SolanaSDK.Pool]>
    func getPoolWithTokenBalances(pool: SolanaSDK.Pool) -> Single<SolanaSDK.Pool>
}

extension SolanaSDK: SwapTokenAPIClient {}

extension SwapToken {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            let sourceWalletPubkey = PublishRelay<String?>()
            let destinationWalletPubkey = PublishRelay<String?>()
            let amount = PublishRelay<String?>()
            let estimatedAmount = PublishRelay<String?>()
            let slippage = PublishRelay<Double>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let isLoading: Driver<Bool>
            let error: Driver<String?>
            let sourceWallet: Driver<Wallet?>
            let destinationWallet: Driver<Wallet?>
            let amount: Driver<Double?>
            let estimatedAmount: Driver<Double?>
        }
        
        // MARK: - Dependencies
        private let repository: WalletsRepository
        private let apiClient: SwapTokenAPIClient
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private lazy var poolsSubject = LazySubject<[SolanaSDK.Pool]>(request: apiClient.getSwapPools())
        private let isLoadingSubject = PublishRelay<Bool>()
        private let errorSubject = PublishRelay<String?>()
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let currentPoolSubject = BehaviorRelay<SolanaSDK.Pool?>(value: nil)
        
        private let amountSubject = BehaviorRelay<Double?>(value: nil)
        private let estimatedAmountSubject = BehaviorRelay<Double?>(value: nil)
        
        private let slippageSubject = BehaviorRelay<Double>(value: Defaults.slippage)
        
        // MARK: - Initializer
        init(repository: WalletsRepository, apiClient: SwapTokenAPIClient) {
            self.repository = repository
            self.apiClient = apiClient
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                isLoading: isLoadingSubject
                    .asDriver(onErrorJustReturn: false),
                error: errorSubject
                    .asDriver(onErrorJustReturn: nil),
                sourceWallet: sourceWalletSubject
                    .asDriver(),
                destinationWallet: destinationWalletSubject
                    .asDriver(),
                amount: amountSubject
                    .asDriver(),
                estimatedAmount: estimatedAmountSubject
                    .asDriver()
            )
            
            bind()
            reload()
        }
        
        /// Bind subjects
        private func bind() {
            bindInputIntoSubjects()
            bindSubjectsIntoSubjects()
        }
        
        private func bindInputIntoSubjects() {
            // source wallet
            Observable.combineLatest(
                repository.dataObservable,
                input.sourceWalletPubkey
            )
                .map {wallets, pubkey in
                    return wallets?.first(where: {$0.pubkey == pubkey})
                }
                .bind(to: sourceWalletSubject)
                .disposed(by: disposeBag)
            
            // destination wallet
            Observable.combineLatest(
                repository.dataObservable,
                input.destinationWalletPubkey
            )
                .map {wallets, pubkey in
                    return wallets?.first(where: {$0.pubkey == pubkey})
                }
                .bind(to: sourceWalletSubject)
                .disposed(by: disposeBag)
            
            // amount
            input.amount
                .map {$0?.double}
                .bind(to: amountSubject)
                .disposed(by: disposeBag)
            
            // estimated amount
            input.estimatedAmount
                .map {$0?.double}
                .bind(to: estimatedAmountSubject)
                .disposed(by: disposeBag)
            
            // slippage
            input.slippage
                .bind(to: slippageSubject)
                .disposed(by: disposeBag)
        }
        
        private func bindSubjectsIntoSubjects() {
            // pools
            poolsSubject.observable
                .subscribe(onNext: {[weak self] state in
                    switch state {
                    case .initializing, .loading:
                        self?.isLoadingSubject.accept(true)
                        self?.errorSubject.accept(nil)
                    case .loaded:
                        self?.isLoadingSubject.accept(false)
                        self?.errorSubject.accept(nil)
                    case .error(let error):
                        self?.isLoadingSubject.accept(false)
                        self?.errorSubject.accept(error.readableDescription)
                    }
                })
                .disposed(by: disposeBag)
            
            // pools loaded
            let poolsLoaded = poolsSubject.observable
                .filter {$0 == .loaded}
                .map {[weak self] _ in self?.poolsSubject.value}
            
            // current pool
            Observable.combineLatest(
                poolsLoaded,
                sourceWalletSubject.distinctUntilChanged(),
                destinationWalletSubject.distinctUntilChanged()
            )
                .map {(pools, sourceWallet, destinationWallet) in
                    pools?.matchedPool(
                        sourceMint: sourceWallet?.mintAddress,
                        destinationMint: destinationWallet?.mintAddress
                    )
                }
                .flatMap { [weak self] pool -> Single<SolanaSDK.Pool?> in
                    guard let pool = pool, let strongSelf = self else {return .just(nil)}
                    strongSelf.isLoadingSubject.accept(true)
                    strongSelf.errorSubject.accept(nil)
                    return strongSelf.apiClient.getPoolWithTokenBalances(pool: pool)
                        .map(Optional.init)
                        .do(afterSuccess: { [weak self] _ in
                            self?.isLoadingSubject.accept(false)
                            self?.errorSubject.accept(nil)
                        }, afterError: {[weak self] error in
                            self?.isLoadingSubject.accept(false)
                            self?.errorSubject.accept(L10n.CouldNotRetrieveBalancesForThisTokensPair.pleaseTrySelectingAgain)
                        })
                }
                .bind(to: currentPoolSubject)
                .disposed(by: disposeBag)
            
            // estimated amount
            Observable.combineLatest(
                currentPoolSubject.distinctUntilChanged(),
                input.amount.map {$0?.double}
            )
                
        }
        
        // MARK: - Actions
        @objc func reload() {
            poolsSubject.reload()
        }
        
        @objc func chooseSourceWallet() {
            navigationSubject.accept(.chooseSourceWallet)
        }
        
        // MARK: - Helpers
        
    }
}

private extension SwapToken.ViewModel {
    // MARK: - Calculator
    private var sourceDecimals: UInt8? {
        sourceWalletSubject.value?.token.decimals
    }
    
    private var destinationDecimals: UInt8? {
        destinationWalletSubject.value?.token.decimals
    }
    
    private var slippageValue: Double {
        slippageSubject.value
    }
    
    /// Calculate input amount for receving expected amount
    /// - Parameter expectedAmount: expected amount of receiver
    /// - Returns: input amount for receiving expected amount
    func calculateInputAmount(forExpectedAmount expectedAmount: Double?) -> Double? {
        guard let expectedAmount = expectedAmount,
              expectedAmount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let inputAmountLamports = currentPoolSubject.value?.inputAmount(forEstimatedAmount: expectedAmount.toLamport(decimals: destinationDecimals), includeFees: true)
        else {return nil}
        return inputAmountLamports.convertToBalance(decimals: sourceDecimals)
    }
    
    /// Calculate estimated amount for an input amount
    /// - Returns: estimated amount from input amount
    func calculateEstimatedAmount(forInputAmount inputAmount: Double?) -> Double? {
        guard let inputAmount = inputAmount,
              inputAmount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let estimatedAmountLamports = currentPoolSubject.value?.estimatedAmount(forInputAmount: inputAmount.toLamport(decimals: sourceDecimals), includeFees: true)
        else {return nil}
        return estimatedAmountLamports.convertToBalance(decimals: destinationDecimals)
    }
    
    /// Calculate minimum receive amount from input amount
    /// - Returns: minimum receive amount
    func calculateMinimumReceiveAmount() -> Double? {
        guard let amount = amountSubject.value,
              amount > 0,
              let sourceDecimals = sourceDecimals,
              let destinationDecimals = destinationDecimals,
              let estimatedAmountLamports = currentPoolSubject.value?.estimatedAmount(forInputAmount: amount.toLamport(decimals: sourceDecimals), includeFees: true),
              let lamports = currentPoolSubject.value?.minimumReceiveAmount(estimatedAmount: estimatedAmountLamports, slippage: slippageValue)
        else {return nil}
        return lamports.convertToBalance(decimals: destinationDecimals)
    }
}
