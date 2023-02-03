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
        let view = NewHistoryView(
            viewModel: .init(
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
        )
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
