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
    
    struct Input {
        let selectDerivationPath = PublishSubject<Void>()
        let derivationPath = PublishSubject<Path>()
    }
    struct Output {
        let accountsViewModel = BEListViewModel<Account>()
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
            navigatingScene: input.selectDerivationPath
                .map {_ in DerivableAccountsNavigatableScene.selectDerivationPath}
                .asDriver(onErrorJustReturn: .selectDerivationPath)
        )
        
        bind()
    }
    
    func bind() {
        input.derivationPath
            .map {[try Account(phrase: self.phrases, network: Defaults.apiEndPoint.network, derivationPath: $0)]}
            .subscribe(onNext: {[weak self] accounts in
                self?.output.accountsViewModel.overrideData(by: accounts)
            })
            .disposed(by: disposeBag)
        
        input.derivationPath
            .bind(to: output.selectedDerivationPath)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @objc func selectDerivationPath() {
        input.selectDerivationPath.onNext(())
    }
}
