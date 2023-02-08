//
//  HomeView.swift
//  p2p_wallet
//
//  Created by Ivan on 08.08.2022.
//

import KeyAppUI
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @StateObject var globalAppState: GlobalAppState = .shared

    let viewModelWithTokens: HomeWithTokensViewModel
    let emptyViewModel: HomeEmptyViewModel

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .pending:
                HomeSkeletonView()
            case .withTokens:
                navigation {
                    HomeWithTokensView(viewModel: viewModelWithTokens)
                }
            case .empty:
                navigation {
                    HomeEmptyView(viewModel: emptyViewModel)
                }
            }

            if globalAppState.shouldPlayAnimationOnHome == true {
                LottieView(
                    lottieFile: "ApplauseAnimation",
                    loopMode: .playOnce,
                    contentMode: .scaleAspectFill
                ) { [globalAppState] in
                    globalAppState.shouldPlayAnimationOnHome = false
                }
                .allowsHitTesting(false)
                .ignoresSafeArea(.all)
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
                                            .font(uiFont: .font(of: .text1, weight: .semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        )
                    }
                }
        }
        .onAppear {
            viewModel.updateAddressIfNeeded()
        }
    }
}

// MARK: - AnalyticView

extension HomeView: AnalyticView {
    var analyticId: String { "Main_New" }
}
