//
//  SwapToken.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 03/06/2021.
//

import Foundation
import RxSwift
import RxCocoa

extension SwapToken {
    class ViewModel: ViewModelType {
        // MARK: - Nested type
        struct Input {
            let sourceWalletPubkey = PublishRelay<String?>()
            let destinationWalletPubkey = PublishRelay<String?>()
        }
        struct Output {
            let navigationScene: Driver<NavigatableScene?>
            let isLoading: Driver<Bool>
            let sourceWallet: Driver<Wallet?>
            let destinationWallet: Driver<Wallet?>
        }
        
        // MARK: - Dependencies
        private let repository: WalletsRepository
        
        // MARK: - Properties
        private let disposeBag = DisposeBag()
        
        let input: Input
        let output: Output
        
        // MARK: - Subject
        private let navigationSubject = BehaviorRelay<NavigatableScene?>(value: nil)
        private let poolsSubject = BehaviorRelay<[SolanaSDK.Pool]>(value: [])
        private let isLoadingSubject = PublishSubject<Bool>()
        private let sourceWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        private let destinationWalletSubject = BehaviorRelay<Wallet?>(value: nil)
        
        // MARK: - Initializer
        init(repository: WalletsRepository) {
            self.repository = repository
            
            self.input = Input()
            self.output = Output(
                navigationScene: navigationSubject
                    .asDriver(onErrorJustReturn: nil),
                isLoading: isLoadingSubject
                    .asDriver(onErrorJustReturn: false),
                sourceWallet: sourceWalletSubject
                    .asDriver(),
                destinationWallet: destinationWalletSubject
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
        }
        
        private func bindSubjectsIntoSubjects() {
            let poolLoaded = poolsSubject.map {!$0.isEmpty}
            
            poolLoaded
                .map {!$0}
                .bind(to: isLoadingSubject)
                .disposed(by: disposeBag)
            
        }
        
        // MARK: - Actions
        @objc func reload() {
            
        }
        
        @objc func chooseSourceWallet() {
            navigationSubject.accept(.chooseSourceWallet)
        }
        
        // MARK: - Helpers
        
    }
}
