import Combine
import Repository
import SwiftUI

struct ActionsPanelView: View {
    let actions: [WalletActionType]
    let balance: String
    let usdAmount: String
    let pnlRepository: AccountPnLRepository
    let action: (WalletActionType) -> Void
    let balanceTapAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            balanceView

            if !usdAmount.isEmpty {
                usdAmountView
            }

            pnlView
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
        RepositoryView(
            repository: pnlRepository
        ) {
            ProgressView()
        } errorView: { error in
            #if !RELEASE
                Text(String(reflecting: error))
                    .foregroundStyle(.red)
            #endif
        } content: { pnl in
            if let pnl {
                Text(L10n.allTheTime(pnl))
                    .font(uiFont: .font(of: .text3))
                    .foregroundColor(Color(.night))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.snow))
        .cornerRadius(8)
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
