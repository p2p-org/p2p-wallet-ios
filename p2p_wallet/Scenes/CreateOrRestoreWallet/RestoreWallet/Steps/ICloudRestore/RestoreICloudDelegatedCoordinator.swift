// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Onboarding
import SwiftUI

final class RestoreICloudDelegatedCoordinator: DelegatedCoordinator<RestoreICloudState> {
    override func buildViewController(for state: RestoreICloudState) -> UIViewController? {
        switch state {
        case .signIn:
            return nil
        case let .chooseWallet(accounts):
            return handleSignInKeychain(accounts: accounts)
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

private extension RestoreICloudDelegatedCoordinator {
    func handleSignInKeychain(accounts: [ICloudAccount]) -> UIViewController {
        let vm = ICloudRestoreViewModel(accounts: accounts)

        vm.coordinatorIO.back.sink { [stateMachine] process in
            process.start { _ = try await stateMachine <- .back }
        }.store(in: &subscriptions)

        vm.coordinatorIO.info.sink { [weak self] process in
            process.start { self?.openInfo() }
        }.store(in: &subscriptions)

        vm.coordinatorIO.restore.sink { [stateMachine] process in
            process.start {
                _ = try await stateMachine <- .restoreWallet(account: process.data)
            }
        }.store(in: &subscriptions)

        return UIHostingController(rootView: ICloudRestoreScreen(viewModel: vm))
    }
}
