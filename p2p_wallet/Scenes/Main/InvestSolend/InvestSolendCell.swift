//
//  InvestSolendCell.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.09.2022.
//

import KeyAppUI
import Solend
import SwiftUI

struct InvestSolendCell: View {
    let asset: SolendConfigAsset
    let deposit: String?
    let apy: String?
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let logo = asset.logo, let url = URL(string: logo) {
                ImageView(withURL: url)
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
            } else {
                Circle()
                    .fill(Color(Asset.Colors.mountain.color))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let deposit = deposit {
                    Text("\(deposit) \(asset.symbol)")
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .apply(style: .text2)
                } else {
                    Text(asset.symbol)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .apply(style: .text2)
                }
                Text(asset.name)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .apply(style: .label1)
            }
            Spacer()

            Text((apy ?? "0").formatApy)
                .foregroundColor(Color(Asset.Colors.night.color))
                .apply(style: .text2)
                .skeleton(with: isLoading, size: CGSize(width: 40, height: 20))
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }
}

struct InvestSolendCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InvestSolendCell(
                asset: .init(
                    name: "Solana",
                    symbol: "SOL",
                    decimals: 9,
                    mintAddress: "",
                    logo: nil
                ),
                deposit: "12.3221",
                apy: "2.31231",
                isLoading: false
            )
        }
    }
}
