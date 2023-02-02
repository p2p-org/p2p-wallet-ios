//
//  NewHistoryCoordinator.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 31.01.2023.
//

import Foundation
import SwiftUI

class NewHistoryCoordinator: SmartCoordinator<Void> {
    override func build() -> UIViewController {
        let view = NewHistoryView(viewModel: .init(initialHistoryItem: []))
        return UIHostingController(rootView: view)
    }
}
