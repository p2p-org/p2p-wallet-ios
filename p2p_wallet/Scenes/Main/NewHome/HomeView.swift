import KeyAppUI
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @StateObject var globalAppState: GlobalAppState = .shared

    let viewModelWithTokens: HomeAccountsViewModel
    let emptyViewModel: HomeEmptyViewModel

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .pending:
                HomeSkeletonView()
            case .withTokens:
                navigation {
                    HomeAccountsView(viewModel: viewModelWithTokens)
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
        .onAppear {
            viewModel.viewAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.viewAppeared()
        }
    }

    func navigation<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationView {
            ZStack {
                Color(Asset.Colors.smoke.color)
                    .edgesIgnoringSafeArea(.all)
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
                                        Color(Asset.Colors.snow.color)
                                            .cornerRadius(80)
                                        HStack(spacing: 5) {
                                            Image(uiImage: .walletNavigation)
                                            Text(viewModel.address)
                                                .fontWeight(.semibold)
                                                .apply(style: .text3)
                                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                    }
                                }
                            )
                        }
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
