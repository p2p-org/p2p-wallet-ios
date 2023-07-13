//
//  SolendDepositView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.10.2022.
//

import KeyAppUI
import SwiftUI

struct SolendUserDepositItem: Hashable {
    var id: String
    var logo: String?
    var title: String
    var subtitle: String
    var rightTitle: String
}

struct SolendDepositView: View {
    let item: SolendUserDepositItem
    let onDepositTapped: () -> Void
    let onWithdrawTapped: () -> Void

    init(
        item: SolendUserDepositItem,
        onDepositTapped: @escaping () -> Void,
        onWithdrawTapped: @escaping () -> Void
    ) {
        self.item = item
        self.onDepositTapped = onDepositTapped
        self.onWithdrawTapped = onWithdrawTapped
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            info
            buttons
        }
        .padding(16)
        .background(Color(.cloud))
        .cornerRadius(20)
    }

    var info: some View {
        HStack(spacing: 12) {
            if let logo = item.logo, let url = URL(string: logo) {
                CoinLogoView(
                    size: 48,
                    cornerRadius: 12,
                    urlString: url.absoluteString
                ).frame(width: 48, height: 48)
            } else {
                Circle()
                    .fill(Color(.mountain))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .foregroundColor(Color(.night))
                    .apply(style: .text2)
                Text(item.subtitle)
                    .foregroundColor(Color(.mountain))
                    .apply(style: .label1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(item.rightTitle)
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .text2, weight: .semibold))
            }
        }
        .frame(height: 64)
    }

    var buttons: some View {
        HStack(spacing: 8) {
            Button(
                action: {
                    onDepositTapped()
                },
                label: {
                    Text(L10n.addMore)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(.rain))
                        .cornerRadius(12)
                }
            )
            Button(
                action: {
                    onWithdrawTapped()
                },
                label: {
                    Text(L10n.withdraw)
                        .foregroundColor(Color(.night))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color(.rain))
                        .cornerRadius(12)
                }
            )
        }
    }
}

struct SolendDepositView_Previews: PreviewProvider {
    static var previews: some View {
        SolendDepositView(
            item: .init(
                id: "",
                logo: "https://raw.githubusercontent.com/p2p-org/solana-token-list/main/assets/mainnet/BQcdHdAQW1hczDbBi9hiegXAR7A98Q9jx3X3iBBBDiq4/logo.png",
                title: "USDT",
                subtitle: "Yielding 3,73% APY",
                rightTitle: "$ 1.07"
            )
        ) {} onWithdrawTapped: {}
    }
}
