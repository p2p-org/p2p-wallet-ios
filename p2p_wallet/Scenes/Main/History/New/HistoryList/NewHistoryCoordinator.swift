//
//  NewHistoryCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import KeyAppUI
import SwiftUI

class NewHistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let vm = NewHistoryViewModel()

        vm.actionSubject
            .sink { [weak self] action in
                guard let self = self else { return }

                let coordinator: TransactionDetailCoordinator

                switch action {
                case let .openParsedTransaction(trx):
                    coordinator = TransactionDetailCoordinator(
                        input: .parsedTransaction(trx),
                        style: .passive,
                        presentingViewController: self.presentation.presentingViewController
                    )
                case let .openHistoryTransaction(trx):
                    coordinator = TransactionDetailCoordinator(
                        input: .historyTransaction(trx),
                        style: .passive,
                        presentingViewController: self.presentation.presentingViewController
                    )
                }

                self
                    .coordinate(to: coordinator)
                    .sink { _ in }
                    .store(in: &self.subscriptions)
            }
            .store(in: &subscriptions)

        let view = NewHistoryView(viewModel: vm)
        let vc = UIHostingControllerWithoutNavigation(rootView: view)
        vc.navigationIsHidden = false
        vc.title = L10n.history
        vc.view.backgroundColor = Asset.Colors.smoke.color

        vc.viewDidAppear.sink {
            vc.navigationItem.largeTitleDisplayMode = .always
        }.store(in: &subscriptions)

        return vc
    }
}
