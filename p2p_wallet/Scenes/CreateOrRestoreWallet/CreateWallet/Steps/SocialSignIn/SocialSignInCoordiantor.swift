// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation

class SocialSignInCoordinator: Coordinator<Void> {
    private(set) var viewController: SocialSignInViewController?

    let parent: UINavigationController
    let createWalletViewModel: CreateWalletViewModel

    var result = PassthroughSubject<Void, Never>()

    init(parent: UINavigationController, createWalletViewModel: CreateWalletViewModel) {
        self.parent = parent
        self.createWalletViewModel = createWalletViewModel
        super.init()
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewController = viewController ??
            SocialSignInViewController(viewModel: .init(createWalletViewModel: createWalletViewModel))

        viewController.viewModel.output.onInfo.sink { [weak self] in self?.showInfo() }
            .store(in: &subscriptions)

        print("Start!!!!!")
        parent.setViewControllers([viewController], animated: true)
        return result.eraseToAnyPublisher()
    }

    func showInfo() {
        let vc = WLMarkdownVC(
            title: L10n.termsOfUse.uppercaseFirst,
            bundledMarkdownTxtFileName: "Terms_of_service"
        )
        viewController?.present(vc, animated: true)
    }
}
