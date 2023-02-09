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
                switch action {
                case let .openDetailByRendableItem(item):
                    self.coordinate(
                        to: TransactionDetailCoordinator(
                            transaction: item,
                            style: .passive,
                            presentingViewController: self.presentation.presentingViewController
                        )
                    )
                    .sink { _ in }
                    .store(in: &self.subscriptions)
                default:
                    break
                }
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
