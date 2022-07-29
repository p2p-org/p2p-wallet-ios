//
//  CreateWallet.ViewModel.swift
//  p2p_wallet
//
//  Created by Chung Tran on 19/02/2021.
//

import AnalyticsManager
import Resolver
import RxCocoa
import RxSwift
import SolanaSwift
import UIKit

protocol CreateWalletViewModelType: AnyObject {
    var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> { get }

    func kickOff()
    func verifyPhrase(_ phrases: [String])
    func handlePhrases(_ phrases: [String])

    func navigateToCreatePhrases()
    func back()
}

extension CreateWallet {
    class ViewModel: CreateWalletViewModelType {
        // MARK: - Dependencies

        @Injected private var handler: CreateOrRestoreWalletHandler
        @Injected private var analyticsManager: AnalyticsManager

        // MARK: - Properties

        private var phrases: [String]?

        var navigatableSceneDriver: Driver<CreateWallet.NavigatableScene?> {
            navigationSubject.asDriver()
        }

        // MARK: - Subjects

        private let navigationSubject = BehaviorRelay<CreateWallet.NavigatableScene?>(value: nil)

        deinit {
            debugPrint("\(String(describing: self)) deinited")
        }

        func kickOff() {
            navigationSubject.accept(.explanation)
        }

        func verifyPhrase(_ phrases: [String]) {
            navigationSubject.accept(.verifyPhrase(phrases))
        }

        func handlePhrases(_ phrases: [String]) {
            self.phrases = phrases
            finish()
        }

        private func finish() {
            navigationSubject.accept(.dismiss)
            handler.creatingWalletDidComplete(
                phrases: phrases,
                derivablePath: .default,
                name: nil
            )
        }

        func navigateToCreatePhrases() {
            analyticsManager.log(event: .createSeedInvoked)
            navigationSubject.accept(.createPhrases)
        }

        func back() {
            navigationSubject.accept(.back)
            navigationSubject.accept(.none)
        }
    }
}
