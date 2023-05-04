// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import Resolver
import SwiftUI

final class RestoreSeedPhraseDelegatedCoordinator: DelegatedCoordinator<RestoreSeedState> {
    @Injected private var helpLauncher: HelpCenterLauncher

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
        helpLauncher.launch()
    }
}

private extension RestoreSeedPhraseDelegatedCoordinator {
    func signInViewController() -> UIViewController {
        let viewModel = SeedPhraseRestoreWalletViewModel()
        viewModel.finishedWithSeed.sinkAsync { [weak viewModel, stateMachine] phrase in
            viewModel?.isSeedFocused = false
            _ = try await stateMachine <- .chooseDerivationPath(phrase: phrase)
        }.store(in: &subscriptions)

        viewModel.back.sinkAsync { [weak viewModel, stateMachine] _ in
            viewModel?.isSeedFocused = false
            _ = try await stateMachine <- .back
        }.store(in: &subscriptions)

        viewModel.info.sinkAsync { [weak self] _ in
            self?.openInfo()
        }.store(in: &subscriptions)
        return UIHostingController(rootView: SeedPhraseRestoreWalletView(viewModel: viewModel))
    }

    func chooseDerivationPathViewController(phrase: [String]) -> UIViewController {
        let viewModel = DerivableAccountsViewModel(phrases: phrase)
        let view = DerivableAccountsView(viewModel: viewModel)
        let viewController = view.asViewController(withoutUIKitNavBar: false)

        viewModel.didSucceed.sinkAsync { [stateMachine] phrase, path in
            _ = try await stateMachine <- .restoreWithSeed(phrase: phrase, path: path)
        }.store(in: &subscriptions)

        viewModel.back.sinkAsync { [stateMachine] _ in
            _ = try await stateMachine <- .back
        }.store(in: &subscriptions)

        viewModel.selectDerivableType.sink { [weak viewModel, weak viewController] derivablePath in
            let vc = SelectDerivableType.ViewController(currentType: derivablePath.type) { derivableType in
                viewModel?.select(derivableType: derivableType)
                viewModel?.logSelection(derivableType: derivableType)
            }
            viewController?.present(vc, animated: true)
        }.store(in: &subscriptions)

        return viewController
    }
}
