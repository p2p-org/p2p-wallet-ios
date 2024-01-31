import Combine
import SwiftUI

struct ActionsPanelView: View {
    let actions: [WalletActionType]
    let balance: String
    let usdAmount: String
    let action: (WalletActionType) -> Void
    let balanceTapAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if !balance.isEmpty {
                Text(balance)
                    .font(uiFont: .font(of: 64, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(.night))
                    .padding(.top, 18)
                    .padding(.bottom, usdAmount.isEmpty ? 24 : 12)
                    .onTapGesture {
                        balanceTapAction?()
                    }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .padding(.top, 24)
            }
            if !usdAmount.isEmpty {
                Text(usdAmount)
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(.night))
                    .padding(.bottom, 25)
            }
            HStack(spacing: 12) {
                ForEach(actions, id: \.text) { actionType in
                    tokenOperation(title: actionType.text, image: actionType.icon) {
                        action(actionType)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
        }
        .background(Color(.smoke))
    }

    private func tokenOperation(title: String, image: ImageResource, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 4) {
                    Image(image)
                        .resizable()
                        .frame(width: 52, height: 52)
                        .scaledToFit()
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .label2)
                        .foregroundColor(Color(.night))
                }
            }
        )
    }
}

#Preview {
    ActionsPanelView(
        actions: [.cashOut, .send, .swap],
        balance: "1789.91 USDC", usdAmount: "1789.91"
    ) { _ in

    } balanceTapAction: {}
}
