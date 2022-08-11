//
//  HomeView.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import BottomSheet
import KeyAppUI
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
            navigation {
                HomeWithTokensView(viewModel: viewModelWithTokens)
            }
        case .empty:
            navigation {
                HomeEmptyView(viewModel: emptyViewModel)
            }
        }
    }

    func navigation<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationView {
            content()
                .navigationBarTitleDisplayMode(.inline)
                .navigationViewStyle(StackNavigationViewStyle())
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Button(
                            action: {
                                viewModel.copyToClipboard()
                            },
                            label: {
                                ZStack {
                                    Color(Asset.Colors.rain.color)
                                        .cornerRadius(80)
                                    HStack(spacing: 9) {
                                        Image(uiImage: .walletNavigation)
                                        Text(viewModel.address)
                                            .foregroundColor(Color(Asset.Colors.mountain.color))
                                            .font(uiFont: .font(of: .text1, weight: .bold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        )
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                viewModel.receive()
                            },
                            label: {
                                Image(uiImage: .scanQr)
                            }
                        )
                    }
                }
        }
    }
}
