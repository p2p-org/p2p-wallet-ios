//
//  RecipientCell.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.2022.
//

import SwiftUI
import KeyAppUI
import Send

struct RecipientCell: View {
    let recipient: Recipient
    
    var body: some View {
        switch recipient.category {
        case let .username(name, domain):
            switch domain {
            case "key":
                cell(image: Image(uiImage: .appIconSmall), title: "@\(name).key")
            default:
                cell(image: Image(uiImage: .newWalletCircle), title: "\(name).\(domain)", subtitle: "\(recipient.address.prefix(7))...\(recipient.address.suffix(7))")
            }
        case .solanaAddress:
            cell(image: Image(uiImage: .newWalletCircle), title: "\(recipient.address.prefix(7))...\(recipient.address.suffix(7))")
        case let .solanaTokenAddress(_, token):
            cell(image: CoinLogoImageViewRepresentable(size: 48, token: token), title: "\(recipient.address.prefix(7))...\(recipient.address.suffix(7))", subtitle: "\(token.name) \(L10n.tokenAccount)")
        default:
            cell(image: Image(uiImage: .newWalletCircle), title: recipient.address)
        }
    }
    
    private func cell(image: some View, title: String, subtitle: String? = nil) -> some View {
        HStack {
            image
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct RecipientCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            RecipientCell(recipient: Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill", domain: "key"),
                attributes: [.funds]
            ))
            RecipientCell(recipient: Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .username(name: "kirill", domain: "sol"),
                attributes: [.funds]
            ))
            RecipientCell(recipient: Recipient(
                address: "6uc8ajD1mwNPeLrgP17FKNpBgHifqaTkyYySgdfs9F26",
                category: .solanaAddress,
                attributes: [.funds]
            ))
            RecipientCell(recipient: Recipient(
                address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                category: .solanaTokenAddress(
                    walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                    token: .usdc
                ),
                attributes: [.funds]
            ))
        }
    }
}
