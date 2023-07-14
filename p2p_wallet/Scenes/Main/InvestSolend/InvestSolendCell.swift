//
//  InvestSolendCell.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.09.2022.
//

import Solend
import SwiftUI

struct InvestSolendCell: View {
    let asset: SolendConfigAsset
    let amount: String?
    let apy: String?
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let logo = asset.logo, let url = URL(string: logo) {
                CoinLogoView(
                    size: 48,
                    cornerRadius: 12,
                    urlString: url.absoluteString
                )
                .clipShape(Circle())
                .frame(width: 48, height: 48)
            } else {
                Circle()
                    .fill(Color(.mountain))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                if let deposit = amount {
                    Text("\(deposit) \(asset.symbol)")
                        .foregroundColor(Color(.night))
                        .apply(style: .text2)
                } else {
                    Text(asset.symbol)
                        .foregroundColor(Color(.night))
                        .apply(style: .text2)
                }
                Text(asset.name)
                    .foregroundColor(Color(.mountain))
                    .apply(style: .label1)
            }
            Spacer()
            Text(apy?.formatApy ?? "N/A")
                .foregroundColor(Color(apy != nil ? .night : .rose))
                .font(uiFont: .font(of: .text2, weight: .semibold))
                .skeleton(with: isLoading, size: CGSize(width: 40, height: 20))
        }
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
                amount: "12.3221",
                apy: "2.31231",
                isLoading: false
            )
        }
    }
}
