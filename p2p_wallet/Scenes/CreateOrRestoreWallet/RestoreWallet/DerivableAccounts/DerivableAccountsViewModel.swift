//
//  DerivableAccountsViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/05/2021.
//

import Foundation
import RxCocoa
import RxSwift

enum DerivableAccountsNavigatableScene {
    case selectDerivationPath
}

protocol AccountRestorationHandler {
    func accountDidRestore(_ account: SolanaSDK.Account)
}

class DerivableAccountsViewModel: ViewModelType {
    // MARK: - Nested type
    typealias Path = SolanaSDK.DerivablePath
    
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
    private let handler: AccountRestorationHandler
    
    let input: Input
    let output: Output
    
    // MARK: - Subjects
    
    // MARK: - Initializer
    init(phrases: [String], pricesFetcher: PricesFetcher, handler: AccountRestorationHandler) {
        self.phrases = phrases
        self.handler = handler
        
        self.input = Input()
        self.output = Output(
            accountsViewModel: .init(phrases: phrases, pricesFetcher: pricesFetcher),
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
    
    func restoreAccount() -> Single<SolanaSDK.Account> {
        // cancel any requests
        output.accountsViewModel.cancelRequest()
        
        // if account is successfully loaded
        if let account = output.accountsViewModel.data.first?.info {
            return .just(account)
        }
        
        // load account
        return Single.create { observer in
            DispatchQueue.global().async { [weak self] in
                guard let phrases = self?.phrases,
                      let path = self?.output.selectedDerivationPath.value
                else {
                    observer(.failure(SolanaSDK.Error.unknown))
                    return
                }
                do {
                    let account = try SolanaSDK.Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivablePath: path)
                    observer(.success(account))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create()
        }
            .observe(on: MainScheduler.instance)
    }
    
    func restoringDidComplete(account: SolanaSDK.Account) {
        handler.accountDidRestore(account)
    }
}
