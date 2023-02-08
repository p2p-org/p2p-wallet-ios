//
//  NewHistoryCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import SwiftUI
import KeyAppUI

class NewHistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let vm = NewHistoryViewModel(
            initialSections: [
                .init(
                    title: "Today",
                    items: NewHistoryItemView_Previews.items.map { .rendable($0) }
                ),
                .init(
                    title: "Yesterday",
                    items: NewHistoryItemView_Previews.items.map { .rendable($0) }
                )
            ]
        )
        
        vm.actionSubject
            .sink { [weak self] action in
                guard let self = self else { return }
                switch action {
                case let .openDetailByID(id):
                    self.coordinate(to: TransactionDetailCoordinator(presentingViewController: self.presentation.presentingViewController))
                        .sink { }
                        .store(in: &self.subscriptions)
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
