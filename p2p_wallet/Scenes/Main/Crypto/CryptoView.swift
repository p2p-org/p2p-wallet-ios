//
//  CryptoView.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 12/07/23.
//

import KeyAppUI
import SwiftUI

/// View of `Crypto` scene
struct CryptoView: View {
    
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoViewModel
    
    // MARK: - Initializer
    
    init(viewModel: CryptoViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View content

    private var header: some View {
        ActionsPanelView(
            actions: viewModel.actions,
            balance: viewModel.balance,
            usdAmount: "",
            action: { _ in
                //
            }
        )
    }

    var body: some View {
        switch viewModel.state {
        case .pending:
            header
        case .empty:
            header
        case .tokens:
            header
        }
    }
}

struct CryptoView_Previews: PreviewProvider {
    static var previews: some View {
        CryptoView(viewModel: CryptoViewModel(navigation: .init()))
    }
}
