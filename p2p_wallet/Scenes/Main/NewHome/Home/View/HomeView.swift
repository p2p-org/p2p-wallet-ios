//
//  HomeView.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let viewModelWithTokens: HomeWithTokensViewModel
    let emptyViewModel: HomeEmptyViewModel

    var body: some View {
        switch viewModel.state {
        case .pending:
            ActivityIndicator(isAnimating: true) {
                $0.style = .large
            }
        case .withTokens:
            HomeWithTokensView(viewModel: viewModelWithTokens)
        case .empty:
            HomeEmptyView(viewModel: emptyViewModel)
        }
    }
}
