//
//  DerivableAccountsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import RxCocoa
import RxSwift
import BECollectionView

enum DerivableAccountsNavigatableScene {
    case selectDerivationPath
}

class DerivableAccountsViewModel: ViewModelType {
    // MARK: - Nested type
    typealias Path = SolanaSDK.DerivablePath
    typealias Account = SolanaSDK.Account
    
    class AccountsListViewModel: BEListViewModel<Account> {
        private let phrases: [String]
        var derivablePath: Path?
        init(phrases: [String]) {
            self.phrases = phrases
            super.init(initialData: [])
        }
        override func createRequest() -> Single<[Account]> {
            Single.create { [weak self] observer in
                DispatchQueue.global(qos: .default).async { [weak self] in
                    guard let strongSelf = self else {
                        observer(.failure(SolanaSDK.Error.unknown))
                        return
                    }
                    do {
                        let accounts = [
                            try Account(phrase: strongSelf.phrases, network: Defaults.apiEndPoint.network, derivablePath: strongSelf.derivablePath)
                        ]
                        observer(.success(accounts))
                    } catch {
                        observer(.failure(error))
                    }
                }
                return Disposables.create()
            }
                .observe(on: MainScheduler.instance)
        }
    }
    
    struct Input {
        let selectDerivationPath = PublishSubject<Void>()
        let derivationPath = PublishSubject<Path>()
    }
    struct Output {
        let accountsViewModel: AccountsListViewModel
        let selectedDerivationPath = BehaviorRelay<Path?>(value: nil)
        
        let navigatingScene: Driver<DerivableAccountsNavigatableScene>
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let phrases: [String]
    let input: Input
    let output: Output
    
    // MARK: - Subjects
    
    // MARK: - Initializer
    init(phrases: [String]) {
        self.phrases = phrases
        
        self.input = Input()
        self.output = Output(
            accountsViewModel: .init(phrases: phrases),
            navigatingScene: input.selectDerivationPath
                .map {_ in DerivableAccountsNavigatableScene.selectDerivationPath}
                .asDriver(onErrorJustReturn: .selectDerivationPath)
        )
        
        bind()
    }
    
    func bind() {
        input.derivationPath
            .bind(to: output.selectedDerivationPath)
            .disposed(by: disposeBag)
        
        input.derivationPath
            .subscribe(onNext: {[weak self] derivablePath in
                self?.output.accountsViewModel.derivablePath = derivablePath
                self?.output.accountsViewModel.reload()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func selectDerivationPath() {
        input.selectDerivationPath.onNext(())
    }
}
