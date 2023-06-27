//
//  ScanQrCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 09.08.2022.
//

import Combine
import Foundation
import Resolver
import UIKit

final class ScanQrCoordinator: Coordinator<String?> {
    private let navigationController: UINavigationController

    private let resultSubject = PassthroughSubject<String?, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<String?, Never> {
        let vc = QrCodeScannerVC()
        vc.callback = { [weak self] code in
            self?.resultSubject.send(code)
            return true
        }
        vc.onClose = { [weak self] in
            self?.resultSubject.send(nil)
        }
        navigationController.present(vc, animated: true)
        return resultSubject.first().eraseToAnyPublisher()
    }
}
