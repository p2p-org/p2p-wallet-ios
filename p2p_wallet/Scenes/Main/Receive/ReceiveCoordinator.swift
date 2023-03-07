import Combine
import Foundation
import SolanaSwift
import SwiftUI
import Resolver

final class ReceiveCoordinator: Coordinator<Void> {
    @Injected private var nameStorage: NameStorageType

    private let navigationController: UINavigationController
    private let pubKey: PublicKey
    private let wallet: Wallet?

    init(
        navigationController: UINavigationController,
        pubKey: PublicKey,
        wallet: Wallet? = nil
    ) {
        self.navigationController = navigationController
        self.pubKey = pubKey
        self.wallet = wallet
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = ReceiveView(
            viewModel: .init(
                address: pubKey.base58EncodedString,
                username: nameStorage.getName(),
                qrCenterImage: wallet?.token.image
            )
        )
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.title = L10n.receiveOn(wallet?.token.symbol ?? "", "Solana")
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
        return viewController.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}
