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
    let input: Input
    let output: Output
    
    // MARK: - Subjects
    
    // MARK: - Initializer
    init(phrases: [String], pricesFetcher: PricesFetcher) {
        self.phrases = phrases
        
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
}
