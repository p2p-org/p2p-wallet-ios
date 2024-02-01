import Combine
import SwiftUI

/// View of `Crypto` scene
struct CryptoView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoViewModel

    private let actionsPanelViewModel: CryptoActionsPanelViewModel
    private let accountsViewModel: CryptoAccountsViewModel

    // MARK: - Initializer

    init(
        viewModel: CryptoViewModel,
        actionsPanelViewModel: CryptoActionsPanelViewModel,
        accountsViewModel: CryptoAccountsViewModel
    ) {
        self.viewModel = viewModel
        self.actionsPanelViewModel = actionsPanelViewModel
        self.accountsViewModel = accountsViewModel
    }

    // MARK: - View content

    private var actionsPanelView: CryptoActionsPanelView {
        CryptoActionsPanelView(viewModel: actionsPanelViewModel)
    }

    var body: some View {
        ZStack {
            Color(.smoke)
                .edgesIgnoringSafeArea(.all)
            switch viewModel.state {
            case .pending:
                CryptoPendingView()
            case .empty:
                CryptoEmptyView(
                    actionsPanelView: actionsPanelView
                )
            case .accounts:
                CryptoAccountsView(
                    viewModel: accountsViewModel,
                    actionsPanelView: actionsPanelView
                )
            }
        }
        .if(viewModel.state != .pending, transform: { view in
            view.toolbar {
                ToolbarItem(placement: .principal) {
                    Button(
                        action: {
                            viewModel.copyToClipboard()
                        },
                        label: {
                            ZStack {
                                Color(.snow)
                                    .cornerRadius(80)
                                Text("🔗 \(viewModel.address)")
                                    .fontWeight(.semibold)
                                    .apply(style: .text3)
                                    .foregroundColor(Color(.mountain))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                            }
                        }
                    )
                }
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.viewAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.viewAppeared()
        }
        .alert("Update available", isPresented: $viewModel.updateAlert) {
            Button("Update", action: {
                viewModel.openAppstore()
                viewModel.userIsAwareAboutUpdate()
            })
            Button("Cancel", role: .cancel, action: {
                viewModel.userIsAwareAboutUpdate()
            })
        }
        
    }
}
