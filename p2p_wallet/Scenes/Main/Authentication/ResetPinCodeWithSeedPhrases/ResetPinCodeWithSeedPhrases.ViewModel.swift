//
//  ResetPinCodeWithSeedPhrasesViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/04/2021.
//

import Combine
import Resolver
import SolanaSwift
import UIKit

protocol ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableScenePublisher: AnyPublisher<ResetPinCodeWithSeedPhrases.NavigatableScene, Never> { get }
    var errorPublisher: AnyPublisher<Error?, Never> { get }

    func savePincode(_ code: String)
    func handlePhrases(_ phrases: [String])
    func validatePhrases(_ phrases: [String]) -> (status: Bool, error: String?)
}

extension ResetPinCodeWithSeedPhrases {
    @MainActor
    class ViewModel: ObservableObject {
        // MARK: - Dependencies

        @Injected private var storage: PincodeSeedPhrasesStorage

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        // MARK: - Subjects

        @Published private var navigatableScene: NavigatableScene = .enterSeedPhrases
        @Published private var error: Error?
    }
}

extension ResetPinCodeWithSeedPhrases.ViewModel: ResetPinCodeWithSeedPhrasesViewModelType {
    var navigatableScenePublisher: AnyPublisher<ResetPinCodeWithSeedPhrases.NavigatableScene, Never> {
        $navigatableScene.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error?, Never> {
        $error.eraseToAnyPublisher()
    }

    // MARK: - Actions

    func savePincode(_ code: String) {
        storage.save(code)
    }

    func handlePhrases(_ phrases: [String]) {
        guard storage.phrases == phrases else {
            error = SolanaError.other("Seed phrases is not correct")
            return
        }
        navigatableScene = .createNewPasscode
    }

    func validatePhrases(_ phrases: [String]) -> (status: Bool, error: String?) {
        let (status, error) = KeyPhrase.checkPhrase(in: phrases)
        if !status { return (status, error) }

        if storage.phrases != phrases {
            return (false, L10n.wrongOrderOrSeedPhrasePleaseCheckItAndTryAgain)
        }
        return (true, nil)
    }
}
