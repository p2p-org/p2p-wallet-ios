import Combine
import Foundation
import Resolver
import SolanaSwift
import SwiftUI

final class ReceiveCoordinator: SmartCoordinator<Void> {
    private let network: ReceiveNetwork
    private var wrapIntoNavigation: Bool = false

    init(
        network: ReceiveNetwork,
        presentation: SmartCoordinatorPresentation,
        wrapIntoNavigation: Bool = false
    ) {
        self.network = network
        self.wrapIntoNavigation = wrapIntoNavigation
        super.init(presentation: presentation)
    }
    
    init(
        network: ReceiveNetwork,
        navigationController: UINavigationController
    ) {
        self.network = network
        super.init(presentation: SmartCoordinatorPushPresentation(navigationController))
    }

    override func build() -> UIViewController {
        let view = ReceiveView(viewModel: .init(network: network))
        let viewController = UIHostingController(rootView: view)

        switch network {
        case let .solana(symbol, _):
            viewController.navigationItem.title = L10n.receiveOn(symbol, "Solana")
        case let .ethereum(symbol, _):
            viewController.navigationItem.title = L10n.receiveOn(symbol, "Ethereum")
        }

        viewController.hidesBottomBarWhenPushed = true

        return wrapIntoNavigation ? UINavigationController(rootViewController: viewController) : viewController
    }
}
