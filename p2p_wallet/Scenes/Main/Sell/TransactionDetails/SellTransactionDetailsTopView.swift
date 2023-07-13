import SwiftUI
import KeyAppUI

struct SellTransactionDetailsTopView: View {
    let model: Model

    var body: some View {
        VStack(spacing: 20) {
            Text(model.date.string(withFormat: "MMMM dd, yyyy @ HH:mm"))
                .foregroundColor(Color(.mountain))
                .font(uiFont: .font(of: .text3))
            ZStack {
                Color(.smoke)
                    .frame(height: 208)
                tokenView
            }
        }
    }

    private var tokenView: some View {
        VStack(spacing: 16) {
            Image(model.tokenImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(32)
            VStack(spacing: 4) {
                Text(model.tokenAmount.tokenAmountFormattedString(symbol: model.tokenSymbol))
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                Text("≈ \(model.fiatAmount.fiatAmountFormattedString(currency: model.currency))")
                    .foregroundColor(Color(.mountain))
                    .font(uiFont: .font(of: .text2))
            }
        }
    }
}

// MARK: - Model

extension SellTransactionDetailsTopView {
    struct Model {
        let date: Date
        let tokenImage: ImageResource
        let tokenSymbol: String
        let tokenAmount: Double
        let fiatAmount: Double
        let currency: Fiat
    }
}

struct SellTransactionDetailsTopView_Previews: PreviewProvider {
    static var previews: some View {
        SellTransactionDetailsTopView(model: SellTransactionDetailsTopView.Model(
            date: Date(),
            tokenImage: .usdc,
            tokenSymbol: "SOL",
            tokenAmount: 5,
            fiatAmount: 300.05,
            currency: .eur
        ))
    }
}
