import Foundation
import Resolver
import SwiftUI

/// View of `CryptoActionsPanel` scene
struct CryptoActionsPanelView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: CryptoActionsPanelViewModel

    let pnlTapAction: (() -> Void)?

    // MARK: - View content

    var body: some View {
        ActionsPanelView(
            actions: viewModel.actions,
            balance: viewModel.balance,
            usdAmount: "",
            pnlRepository: Resolver.resolve(),
            action: viewModel.actionClicked,
            balanceTapAction: viewModel.balanceTapped,
            pnlTapAction: pnlTapAction
        )
        .onAppear {
            viewModel.viewDidAppear()
        }
    }
}
