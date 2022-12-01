import SwiftUI
import SolanaSwift
import KeyAppUI

struct ChooseWalletTokenItemView: View {
    enum State {
        case first, last, single, other
    }

    let token: Token
    let amount: Double?
    let amountInCurrentFiat: Double
    let state: State

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CoinLogoImageViewRepresentable(size: 48, token: token)
                .frame(width: 48, height: 48)
                .cornerRadius(radius: 48/2, corners: .allCorners)

            VStack(alignment: .leading, spacing: 6) {
                Text(token.name)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.night.color))
                if let amount = amount {
                    Text(amount.tokenAmount(symbol: token.symbol))
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }

            Spacer()

            Text(amountInCurrentFiat.fiatAmount())
                .font(uiFont: .font(of: .text2, weight: .semibold))
                .foregroundColor(Color(Asset.Colors.night.color))
        }
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
        case .single:
            return .allCorners
        case .other:
            return .allCorners
        }
    }
}
