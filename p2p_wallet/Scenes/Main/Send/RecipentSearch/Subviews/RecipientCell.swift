//
//  RecipientCell.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25.11.2022.
//

import KeyAppUI
import Send
import SwiftUI

struct RecipientCell: View {
    @SwiftUI.Environment(\.isEnabled) var isEnabled: Bool

    let recipient: Recipient

    var body: some View {
        switch recipient.category {
        case let .username(name, domain):
            switch domain {
            case "key":
                cell(image: Image(uiImage: .appIconSmall), title: "@\(name).key")
            default:
                cell(
                    image: Image(uiImage: .newWalletCircle),
                    title: RecipientFormatter.username(name: name, domain: domain),
                    subtitle: RecipientFormatter.format(destination: recipient.address)
                )
            }
        case .solanaAddress:
            cell(
                image: Image(uiImage: .newWalletCircle),
                title: RecipientFormatter.format(destination: recipient.address)
            )
        case let .solanaTokenAddress(_, token):
            cell(
                image: CoinLogoImageViewRepresentable(size: 48, token: token),
                title: RecipientFormatter.format(destination: recipient.address),
                subtitle: "\(token.name) \(L10n.tokenAccount)"
            )
        default:
            cell(
                image: Image(uiImage: .newWalletCircle),
                title: RecipientFormatter.format(destination: recipient.address)
            )
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
                    .foregroundColor(isEnabled ? Color(Asset.Colors.night.color) :
                        Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                        .lineLimit(1)
                }
            }

            Spacer()
            if let date = recipient.createdData {
                Text(date.timeAgoDisplay())
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }
}

private extension Date {
    func timeAgoDisplay() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .full
        formatter.doesRelativeDateFormatting = true
        let rel = formatter.string(from: self)
        formatter.doesRelativeDateFormatting = false
        let abs = formatter.string(from: self)
        if rel != abs {
            return rel
        }
        if isThisYear() {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d yyyy"
        }
        return formatter.string(from: self)
    }

    func isThisYear() -> Bool {
        let thisYear = Calendar.current.component(.year, from: Date())
        let dateYear = Calendar.current.component(.year, from: self)
        return dateYear == thisYear
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
            RecipientCell(recipient: Recipient(
                address: "CCtYXZHmeJXxR9U1QLMGYxRuPx5HRP5g3QaXNA4UWqFU",
                category: .solanaTokenAddress(
                    walletAddress: try! .init(string: "9sdwzJWooFrjNGVX6GkkWUG9GyeBnhgJYqh27AsPqwbM"),
                    token: .usdc
                ),
                attributes: [.funds]
            )).disabled(true)
        }
    }
}
