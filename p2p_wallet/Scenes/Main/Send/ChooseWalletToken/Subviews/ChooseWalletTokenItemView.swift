import SwiftUI
import SolanaSwift
import KeyAppUI

struct ChooseWalletTokenItemView: View {
    enum State {
        case first, last, single, other
    }

    let wallet: Wallet
    let state: State

    var body: some View {
        TokenCellView(item: TokenCellViewItem(wallet: wallet), appearance: .other)
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(
                Rectangle()
                    .cornerRadius(radius: state == .other ? 0 : 16, corners: cornerRadius())
                    .foregroundColor(Color(Asset.Colors.snow.color))
            )
            .padding(.horizontal, 16)
    }

    func cornerRadius() -> UIRectCorner {
        switch state {
        case .first:
            return [.topLeft, .topRight]
        case .last:
            return [.bottomLeft, .bottomRight]
        case .single, .other:
            return .allCorners
        }
    }
}
