import SwiftUI
import KeyAppUI

struct SwapPriceImpactView: View {

    @State var priceImpact: JupiterSwapState.SwapPriceImpact

    var body: some View {
        HStack(spacing: 10) {
            Image(uiImage: .solendSubtract)
                .renderingMode(.template)
                .foregroundColor(mainColor)

            Text(L10n.ThePriceIsHigherBecauseOfYourTradeSize.considerSplittingYourTransactionIntoMultipleSwaps)
                .apply(style: .text3)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
        }
        .padding(.all, 12)
        .background(backgroundColor)
        .addBorder(mainColor, cornerRadius: 8)
    }

    private var mainColor: Color {
        switch priceImpact {
        case .medium:
            return Color(Asset.Colors.sun.color)
        case .high:
            return Color(Asset.Colors.rose.color)
        }
    }

    private var backgroundColor: Color {
        switch priceImpact {
        case .medium:
            return Color(Asset.Colors.lightSun.color)
        case .high:
            return Color(Asset.Colors.lightRose.color)
        }
    }

    private var textColor: Color {
        switch priceImpact {
        case .medium:
            return Color(Asset.Colors.night.color)
        case .high:
            return Color(Asset.Colors.rose.color)
        }
    }
}
