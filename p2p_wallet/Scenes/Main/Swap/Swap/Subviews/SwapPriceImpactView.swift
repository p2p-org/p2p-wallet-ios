import SwiftUI
import KeyAppUI

struct SwapPriceImpactView: View {

    let model: Model

    var body: some View {
        HStack(spacing: 10) {
            Image(.solendSubtract)
                .renderingMode(.template)
                .foregroundColor(mainColor)
            Text(model.title)
                .apply(style: .text3)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.leading, 12)
        .background(backgroundColor)
        .addBorder(mainColor, cornerRadius: 8)
    }

    private var mainColor: Color {
        switch model.impact {
        case .medium:
            return Color(Asset.Colors.sun.color)
        case .high:
            return Color(Asset.Colors.rose.color)
        }
    }

    private var backgroundColor: Color {
        switch model.impact {
        case .medium:
            return Color(Asset.Colors.lightSun.color)
        case .high:
            return Color(Asset.Colors.lightRose.color)
        }
    }

    private var textColor: Color {
        switch model.impact {
        case .medium:
            return Color(Asset.Colors.night.color)
        case .high:
            return Color(Asset.Colors.rose.color)
        }
    }
}

// MARK: - Model

extension SwapPriceImpactView {
    struct Model {
        let title: String
        let impact: JupiterSwapState.SwapPriceImpact
    }
}
