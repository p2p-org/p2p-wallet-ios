// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
import Combine
import SwiftUI
import UIKit

final class CreateUsernameCoordinator: Coordinator<Void> {
    private let window: UIWindow
    private var subject = PassthroughSubject<Void, Never>()

    init(window: UIWindow) {
        self.window = window
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = CreateUsernameViewModel()
        let view = CreateUsernameView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        let navigationController = UINavigationController()
        navigationController.setViewControllers([controller], animated: true)
        window.animate(newRootViewController: navigationController)

        viewModel.requireSkip.sink { [unowned self] in
            self.subject.send(())
        }.store(in: &subscriptions)

        return subject.eraseToAnyPublisher()
    }
}
