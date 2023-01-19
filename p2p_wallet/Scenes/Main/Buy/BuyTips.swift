//
//  BuyTips.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 04.10.2022.
//

import KeyAppUI
import SwiftUI

struct BuyTips: View {
    let sourceSymbol: String
    let destinationSymbol: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .center, spacing: 2) {
                Text("1")
                    .fontWeight(.semibold)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.snow.color))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color(Asset.Colors.mint.color))
                    )

                Rectangle()
                    .fill(Color(Asset.Colors.mountain.color))
                    .frame(width: 1, height: 34)

                Text("2")
                    .fontWeight(.semibold)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .frame(width: 24, height: 20)
                    .background(
                        Circle()
                            .stroke(Color(Asset.Colors.mountain.color), lineWidth: 1.5)
                    )
            }
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.buyingAsTheBaseCurrency(sourceSymbol))
                        .apply(style: .text1)
                        .foregroundColor(Color(Asset.Colors.night.color))

                    Text(L10n.purchasingOnTheMoonpaySWebsite)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.exchanging(sourceSymbol, destinationSymbol))
                        .apply(style: .text1)
                        .foregroundColor(Color(Asset.Colors.night.color))
                    Text(L10n.thereWouldBeNoAdditionalCosts)
                        .apply(style: .text4)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }

            Spacer()
        }
        .padding(.all, 20)
        .background(Color(Asset.Colors.smoke.color))
        .cornerRadius(20)
    }
}

struct BuyTips_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BuyTips(sourceSymbol: "SOL", destinationSymbol: "USDC")
                .frame(width: .infinity)
                .padding(.horizontal, 16)
        }
    }
}
