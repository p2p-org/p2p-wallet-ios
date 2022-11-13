//
//  MainCoordinator.swift
//  p2p_wallet
//
//  Created by Ivan on 14.11.2022.
//

import Combine
import Foundation
import Resolver
import UIKit

final class MainCoordinator: Coordinator<Void> {
    private weak var window: UIWindow?
    private let authenticateWhenAppears: Bool

    private let subject = PassthroughSubject<Void, Never>()

    init(window: UIWindow?, authenticateWhenAppears: Bool) {
        self.window = window
        self.authenticateWhenAppears = authenticateWhenAppears
    }

    deinit {
        debugPrint("--- MainCoordinator deinit")
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = Main.ViewModel()
        let view = Main.ViewController(viewModel: viewModel)
        view.authenticateWhenAppears = authenticateWhenAppears

        window?.rootViewController?.view.hideLoadingIndicatorView()
        window?.animate(newRootViewController: view)

        view.onClose = { [unowned self] in
            subject.send()
        }

        return subject.eraseToAnyPublisher()
    }
}
