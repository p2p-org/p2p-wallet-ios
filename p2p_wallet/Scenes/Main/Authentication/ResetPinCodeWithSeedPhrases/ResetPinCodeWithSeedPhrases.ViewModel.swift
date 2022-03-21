//
//  ResetPinCodeWithSeedPhrasesViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import RxCocoa
import RxSwift
import UIKit

protocol ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableSceneDriver: Driver<ResetPinCodeWithSeedPhrases.NavigatableScene> { get }
    var errorDriver: Driver<Error?> { get }

    func savePincode(_ code: String)
    func handlePhrases(_ phrases: [String])
}

extension ResetPinCodeWithSeedPhrases {
    class ViewModel {
        // MARK: - Dependencies

        @Injected private var storage: PincodeSeedPhrasesStorage

        // MARK: - Properties

        private let disposeBag = DisposeBag()

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<NavigatableScene>(value: .enterSeedPhrases)
        private let errorSubject = BehaviorRelay<Error?>(value: nil)
    }
}

extension ResetPinCodeWithSeedPhrases.ViewModel: ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableSceneDriver: Driver<ResetPinCodeWithSeedPhrases.NavigatableScene> {
        navigationSubject.asDriver()
    }

    var errorDriver: Driver<Error?> {
        errorSubject.asDriver()
    }

    // MARK: - Actions

    func savePincode(_ code: String) {
        storage.save(code)
    }

    func handlePhrases(_ phrases: [String]) {
        guard storage.phrases == phrases else {
            errorSubject.accept(SolanaSDK.Error.other("Seed phrases is not correct"))
            return
        }
        navigationSubject.accept(.createNewPasscode)
    }
}
