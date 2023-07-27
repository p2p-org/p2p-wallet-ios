import SwiftUI
import Combine

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
        .onAppear {
            viewModel.viewAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.viewAppeared()
        }
    }
}
