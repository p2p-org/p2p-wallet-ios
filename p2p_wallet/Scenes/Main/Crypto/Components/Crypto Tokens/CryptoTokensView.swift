//
//  CryptoTokensView.swift
//  p2p_wallet
//
//  Created by Zafar Ivaev on 13/07/23.
//

import Foundation
import SwiftUI

/// View of `CryptoTokens` scene
struct CryptoTokensView: View {
    
    // MARK: - Properties

    /// View model
    @ObservedObject var viewModel: CryptoTokensViewModel
    
    // MARK: - Initializer
    
    init(viewModel: CryptoTokensViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View content

    var body: some View {
        Text("CryptoTokens")
    }
}
