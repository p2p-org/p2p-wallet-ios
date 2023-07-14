import SwiftUI

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
            return Color(.sun)
        case .high:
            return Color(.rose)
        }
    }

    private var backgroundColor: Color {
        switch model.impact {
        case .medium:
            return Color(.lightSun)
        case .high:
            return Color(.lightRose)
        }
    }

    private var textColor: Color {
        switch model.impact {
        case .medium:
            return Color(.night)
        case .high:
            return Color(.rose)
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
