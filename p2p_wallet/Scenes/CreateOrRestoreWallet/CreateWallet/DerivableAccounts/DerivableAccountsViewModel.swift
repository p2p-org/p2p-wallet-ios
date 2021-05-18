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
    typealias Path = SolanaSDK.DerivationPath
    typealias Account = SolanaSDK.Account
    
    struct Input {
        let selectDerivationPath = PublishSubject<Void>()
        let derivationPath = PublishSubject<Path>()
    }
    struct Output {
        let navigatingScene: Driver<DerivableAccountsNavigatableScene>
        let selectedDerivationPath: Driver<Path>
        let accounts: Driver<[Account]>
    }
    
    // MARK: - Properties
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
                .asDriver(onErrorJustReturn: .selectDerivationPath),
            selectedDerivationPath: input.derivationPath
                .asDriver(onErrorJustReturn: .bip44),
            accounts: input.derivationPath
                .map {[try Account(phrase: phrases, network: Defaults.apiEndPoint.network, derivationPath: $0)]}
                .asDriver(onErrorJustReturn: [])
        )
    }
    
    // MARK: - Actions
    @objc func selectDerivationPath() {
        input.selectDerivationPath.onNext(())
    }
}
