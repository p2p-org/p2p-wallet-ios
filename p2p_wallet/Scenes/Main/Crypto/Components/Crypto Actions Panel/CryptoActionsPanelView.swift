import Foundation
import SwiftUI

/// View of `CryptoActionsPanel` scene
struct CryptoActionsPanelView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoActionsPanelViewModel

    // MARK: - Initializer

    init(viewModel: CryptoActionsPanelViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - View content

    var body: some View {
        ActionsPanelView(
            actions: viewModel.actions,
            balance: viewModel.balance,
            usdAmount: "",
            action: viewModel.actionClicked,
            balanceTapAction: viewModel.balanceTapped
        )
        .onAppear {
            viewModel.viewDidAppear()
        }
    }
}
