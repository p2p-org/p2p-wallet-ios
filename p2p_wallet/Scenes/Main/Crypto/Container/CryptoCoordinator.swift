import AnalyticsManager
import Combine
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import SolanaSwift
import SwiftUI
import UIKit
import Wormhole

/// The scenes that the `Crypto` scene can navigate to
enum CryptoNavigation: Equatable {
    // With tokens
    case buy
    case receive(publicKey: PublicKey)
    case send
    case swap
    case cashOut
    case earn
    case solanaAccount(SolanaAccount)
    case claim(EthereumAccount, WormholeClaimUserAction?)
    case actions([WalletActionType])
    // Empty
    case topUpCoin(Token)
    // Error
    case error(show: Bool)
}

/// Result type of the `Crypto` scene
typealias CryptoResult = Void

/// Coordinator of `Crypto` scene
final class CryptoCoordinator: Coordinator<CryptoResult> {
    // MARK: - Dependencies

    @Injected private var analyticsManager: AnalyticsManager

    // MARK: - Properties

    /// Navigation controller that handle the navigation stack
    private let navigationController: UINavigationController

    /// Navigation subject
    private let navigation = PassthroughSubject<CryptoNavigation, Never>()

    // MARK: - Initializer

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<CryptoResult, Never> {
        // create viewmodel, view, uihostingcontroller
        let viewModel = CryptoViewModel(navigation: navigation)
        let actionsPanelViewModel = CryptoActionsPanelViewModel(navigation: navigation)
        let accountsViewModel = CryptoAccountsViewModel(navigation: navigation)
        let cryptoView = CryptoView(
            viewModel: viewModel,
            actionsPanelViewModel: actionsPanelViewModel,
            accountsViewModel: accountsViewModel
        )
        let cryptoVC = UIHostingController(rootView: cryptoView)
        cryptoVC.title = L10n.myCrypto
        navigationController.setViewControllers([cryptoVC], animated: false)

        // handle navigation
        navigation
            .flatMap { [unowned self] in
                navigate(to: $0)
            }
            .sink(receiveValue: {})
            .store(in: &subscriptions)

        // return publisher
        return cryptoVC.deallocatedPublisher()
    }

    // MARK: - Navigation

    private func navigate(to scene: CryptoNavigation) -> AnyPublisher<CryptoResult, Never> {
        switch scene {
        case .receive:
            if available(.ethAddressEnabled) {
                let coordinator = SupportedTokensCoordinator(
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator)
                    .eraseToAnyPublisher()
            } else {
                let coordinator = ReceiveCoordinator(
                    network: .solana(tokenSymbol: "SOL", tokenImage: .image(.solanaIcon)),
                    presentation: SmartCoordinatorPushPresentation(navigationController)
                )
                return coordinate(to: coordinator).eraseToAnyPublisher()
            }
        case .swap:
            return coordinate(
                to: JupiterSwapCoordinator(
                    navigationController: navigationController,
                    params: JupiterSwapParameters(
                        dismissAfterCompletion: true,
                        openKeyboardOnStart: true,
                        source: .actionPanel
                    )
                )
            )
            .eraseToAnyPublisher()
        case let .solanaAccount(solanaAccount):
            return coordinate(
                to: AccountDetailsCoordinator(
                    args: .solanaAccount(solanaAccount),
                    presentingViewController: navigationController
                )
            )
            .map { _ in () }
            .eraseToAnyPublisher()
        case let .claim(account, userAction):
            if let userAction, userAction.status == .processing {
                return coordinate(to: TransactionDetailCoordinator(
                    viewModel: .init(userAction: userAction),
                    presentingViewController: navigationController
                ))
                .map { _ in () }
                .eraseToAnyPublisher()
            } else {
                return coordinate(
                    to: WormholeClaimCoordinator(
                        account: account,
                        presentation: SmartCoordinatorPushPresentation(navigationController)
                    )
                )
                .handleEvents(receiveOutput: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .claiming(pendingTrx):
                        self.coordinate(
                            to: TransactionDetailCoordinator(
                                viewModel: .init(userAction: pendingTrx),
                                presentingViewController: self.navigationController
                            )
                        )
                        .sink { _ in }
                        .store(in: &self.subscriptions)
                    }
                })
                .map { _ in () }
                .eraseToAnyPublisher()
            }
        default:
            return Just(())
                .eraseToAnyPublisher()
        }
    }
}
