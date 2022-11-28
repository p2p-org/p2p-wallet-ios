// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import SwiftUI
import Send

class SendCoordinator: Coordinator<Void> {
    let rootViewController: UINavigationController
    
    init(rootViewController: UINavigationController) {
        self.rootViewController = rootViewController
        super.init()
    }
    
    override func start() -> AnyPublisher<Void, Never> {
        let result = PassthroughSubject<Void, Never>()

        // Setup view
        let vm = RecipientSearchViewModel()
        vm.coordinator.selectRecipientPublisher
            .sink { [weak self] (recipient: Recipient) in self?.openSendInput(recipient: recipient) }
            .store(in: &subscriptions)
        
        let view = RecipientSearchView(viewModel: vm)
        let vc = UIHostingController(rootView: view)

        // Push strategy
        rootViewController.pushViewController(vc, animated: true)

        vc.onClose = { result.send() }

        // Back
        return result.eraseToAnyPublisher()
    }
    
    private func openSendInput(recipient: Recipient) {
        coordinate(to: SendInputCoordinator(recipient: recipient, navigationController: rootViewController))
            .sink {}
            .store(in: &subscriptions)
    }
}
