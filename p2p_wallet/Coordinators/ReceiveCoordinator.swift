//
//  ReceiveCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 19.08.2022.
//

import Combine
import Foundation
import SolanaSwift

final class ReceiveCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let pubKey: PublicKey
    private let wallet: Wallet?
    private let isOpeningFromToken: Bool

    init(
        navigationController: UINavigationController,
        pubKey: PublicKey,
        wallet: Wallet? = nil,
        isOpeningFromToken: Bool = false
    ) {
        self.navigationController = navigationController
        self.pubKey = pubKey
        self.wallet = wallet
        self.isOpeningFromToken = isOpeningFromToken
    }

    override func start() -> AnyPublisher<Void, Never> {
        let vm = ReceiveToken.SceneModel(
            solanaPubkey: pubKey,
            solanaTokenWallet: wallet
        )
        let vc = ReceiveToken.ViewController(
            viewModel: vm,
            isOpeningFromToken: isOpeningFromToken
        )
        navigationController.present(vc, animated: true)

        let subject = PassthroughSubject<Void, Never>()
        vc.onClose = {
            subject.send()
        }
        return subject.eraseToAnyPublisher()
    }
}
