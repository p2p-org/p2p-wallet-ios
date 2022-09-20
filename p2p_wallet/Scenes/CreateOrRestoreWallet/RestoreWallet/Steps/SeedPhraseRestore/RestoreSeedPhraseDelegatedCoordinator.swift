// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import SwiftUI

final class RestoreSeedPhraseDelegatedCoordinator: DelegatedCoordinator<RestoreSeedState> {
    override func buildViewController(for state: RestoreSeedState) -> UIViewController? {
        switch state {
        case .signInSeed:
            return signInViewController()

        case let .chooseDerivationPath(phrase):
            return chooseDerivationPathViewController(phrase: phrase)

        case .finish:
            return nil
        }
    }

    private func openInfo() {
        let viewController = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        rootViewController?.present(viewController, animated: true)
    }
}

private extension RestoreSeedPhraseDelegatedCoordinator {
    func signInViewController() -> UIViewController {
        let viewModel = SeedPhraseRestoreWalletViewModel()
        viewModel.finishedWithSeed.sinkAsync { [stateMachine] phrase in
            _ = try await stateMachine <- .chooseDerivationPath(phrase: phrase)
        }.store(in: &subscriptions)

        viewModel.back.sinkAsync { [stateMachine] _ in
            _ = try await stateMachine <- .back
        }.store(in: &subscriptions)

        viewModel.info.sinkAsync { [weak self] _ in
            self?.openInfo()
        }.store(in: &subscriptions)
        return UIHostingController(rootView: SeedPhraseRestoreWalletView(viewModel: viewModel))
    }

    func chooseDerivationPathViewController(phrase: [String]) -> UIViewController {
        let viewModel = NewDerivableAccounts.ViewModel(phrases: phrase)

        viewModel.coordinatorIO.didSucceed.sinkAsync { [stateMachine] phrase, path in
            _ = try await stateMachine <- .restoreWithSeed(phrase: phrase, path: path)
        }.store(in: &subscriptions)

        viewModel.coordinatorIO.back.sinkAsync { [stateMachine] _ in
            _ = try await stateMachine <- .back
        }.store(in: &subscriptions)

        return NewDerivableAccounts.ViewController(viewModel: viewModel)
    }
}
