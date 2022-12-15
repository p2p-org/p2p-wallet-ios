//
//  SellTransactionDetailsTopView.swift
//  p2p_wallet
//
//  Created by Ivan on 14.12.2022.
//

import SwiftUI
import KeyAppUI

struct SellTransactionDetailsTopView: View {
    let model: Model

    var body: some View {
        VStack(spacing: 20) {
            Text(model.date.string(withFormat: "MMMM dd, yyyy @ HH:mm"))
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .font(uiFont: .font(of: .text3))
            ZStack {
                Color(Asset.Colors.smoke.color)
                    .frame(height: 208)
                tokenView
            }
        }
    }

    private var tokenView: some View {
        VStack(spacing: 16) {
            Image(uiImage: model.tokenImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(32)
            VStack(spacing: 4) {
                Text(model.tokenAmount.tokenAmount(symbol: model.tokenSymbol))
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                Text("≈ \(model.fiatAmount.fiatAmount(currency: model.currency))")
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .text2))
            }
        }
    }
}

// MARK: - Model

extension SellTransactionDetailsTopView {
    struct Model {
        let date: Date
        let tokenImage: UIImage
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
