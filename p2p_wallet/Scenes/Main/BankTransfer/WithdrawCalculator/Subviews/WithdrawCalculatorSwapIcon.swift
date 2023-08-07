import KeyAppUI
import SwiftUI

struct WithdrawCalculatorSwapIcon: View {
    var body: some View {
        Image(uiImage: .chevronDown)
            .renderingMode(.template)
            .foregroundColor(Color(Asset.Colors.silver.color))
            .background(
                Circle()
                    .foregroundColor(Color(Asset.Colors.rain.color))
                    .frame(width: 36, height: 36)
            )
    }
}
