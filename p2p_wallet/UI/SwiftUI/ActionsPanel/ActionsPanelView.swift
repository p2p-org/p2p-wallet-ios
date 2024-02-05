import SwiftUI

struct ActionsPanelView: View {
    let actions: [WalletActionType]
    let balance: String
    let usdAmount: String
    let pnlRepository: PnLRepository
    let action: (WalletActionType) -> Void
    let balanceTapAction: (() -> Void)?
    let pnlTapAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            balanceView

            if !usdAmount.isEmpty {
                usdAmountView
            }

            pnlView
                .onTapGesture {
                    pnlTapAction?()
                }
                .padding(.top, usdAmount.isEmpty ? 12 : 0)

            actionsView
                .padding(.top, 36)
        }
        .background(Color(.smoke))
    }

    // MARK: - ViewBuilders

    @ViewBuilder private var balanceView: some View {
        if !balance.isEmpty {
            Text(balance)
                .font(uiFont: .font(of: 64, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(Color(.night))
                .padding(.top, 18)
                .onTapGesture {
                    balanceTapAction?()
                }
        } else {
            Rectangle()
                .fill(Color.clear)
                .padding(.top, 24)
        }
    }

    @ViewBuilder private var usdAmountView: some View {
        Text(usdAmount)
            .font(uiFont: .font(of: .text3))
            .foregroundColor(Color(.night))
    }

    @ViewBuilder private var pnlView: some View {
        PnLView(
            pnlRepository: pnlRepository,
            skeletonSize: .init(width: 100, height: 16)
        ) { pnl in
            if let percentage = pnl?.total?.percent {
                Text(L10n.last24h("\(percentage)"))
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(.night))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.snow))
                    .cornerRadius(8)
            }
        }
        .frame(height: 16)
    }

    @ViewBuilder private var actionsView: some View {
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
