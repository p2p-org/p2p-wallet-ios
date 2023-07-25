import Combine
import KeyAppUI
import SwiftUI

struct ActionsPanelView: View {
    let actions: [WalletActionType]
    let balance: String
    let usdAmount: String
    let action: (WalletActionType) -> Void
    let balanceTapAction: (() -> ())?
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if !balance.isEmpty {
                Text(balance)
                    .font(uiFont: .font(of: 64, weight: .semibold))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.top, 24)
                    .padding(.bottom, usdAmount.isEmpty ? 46 : 12)
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
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .padding(.bottom, 25)
            }
            HStack(spacing: 32) {
                ForEach(actions, id: \.text) { actionType in
                    tokenOperation(title: actionType.text, image: actionType.icon) {
                        action(actionType)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)
        }
        .background(Color(Asset.Colors.smoke.color))
    }

    private func tokenOperation(title: String, image: UIImage, action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                VStack(spacing: 4) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 53, height: 53)
                        .scaledToFit()
                    Text(title)
                        .fontWeight(.semibold)
                        .apply(style: .label2)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            }
        )
    }
}
