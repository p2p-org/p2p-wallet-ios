import Combine
import Onboarding
import Resolver
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
}

private extension RestoreICloudDelegatedCoordinator {
    func handleSignInKeychain(accounts: [ICloudAccount]) -> UIViewController {
        let vm = ICloudRestoreViewModel(accounts: accounts)

        vm.back.sink { [stateMachine] process in
            process.start { _ = try await stateMachine <- .back }
        }.store(in: &subscriptions)

        vm.restore.sink { [stateMachine] process in
            process.start {
                _ = try await stateMachine <- .restoreWallet(account: process.data)
            }
        }.store(in: &subscriptions)

        return UIHostingController(rootView: ICloudRestoreScreen(viewModel: vm))
    }
}
