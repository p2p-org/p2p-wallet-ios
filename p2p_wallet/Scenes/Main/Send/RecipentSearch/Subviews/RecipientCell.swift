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
    let image: AnyView
    let title: String
    let subtitle: String?
    let trailingView: AnyView?
    let multilinesForSubtitle: Bool
    
    init(
        image: AnyView,
        title: String,
        subtitle: String? = nil,
        trailingView: AnyView? = nil,
        multilinesForSubtitle: Bool = false
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.trailingView = trailingView
        self.multilinesForSubtitle = multilinesForSubtitle
    }

    init(
        recipient: Recipient,
        subtitle: String? = nil,
        multilinesForSubtitle: Bool = false
    ) {
        switch recipient.category {
        case let .username(name, domain):
            switch domain {
            case "key":
                image = Image(.appIconSmall).castToAnyView()
                title = "@\(name).key"
                self.subtitle = subtitle
            default:
                image = Image(.newWalletCircle).castToAnyView()
                title = RecipientFormatter.username(name: name, domain: domain)
                self.subtitle = RecipientFormatter.format(destination: recipient.address)
            }
        case .solanaAddress:
            image = Image(.newWalletCircle).castToAnyView()
            title = RecipientFormatter.format(destination: recipient.address)
            self.subtitle = subtitle

        case .ethereumAddress:
            image = Image(.ethereumIcon).castToAnyView()
            title = RecipientFormatter.format(destination: recipient.address)
            self.subtitle = nil

        case let .solanaTokenAddress(_, token):
            image = CoinLogoImageViewRepresentable(size: 48, args: .token(token)).castToAnyView()
            title = RecipientFormatter.format(destination: recipient.address)
            self.subtitle = subtitle ?? "\(token.symbol) \(L10n.tokenAccount)"
        default:
            image = Image(.newWalletCircle).castToAnyView()
            title = RecipientFormatter.format(destination: recipient.address)
            self.subtitle = subtitle
        }

        if let date = recipient.createdData {
            trailingView = Text(date.timeAgoDisplay())
                .apply(style: .label1)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .accessibilityIdentifier("RecipientCell.createdDate")
                .castToAnyView()
        } else {
            trailingView = nil
        }
        self.multilinesForSubtitle = multilinesForSubtitle
    }

    var body: some View {
        HStack {
            image
                .clipShape(Circle())
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                    .foregroundColor(isEnabled ? Color(Asset.Colors.night.color) :
                        Color(Asset.Colors.night.color.withAlphaComponent(0.3)))
                    .lineLimit(1)
                    .accessibilityIdentifier("RecipientCell.title")
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                        .if(multilinesForSubtitle) {
                            $0
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .if(!multilinesForSubtitle) {
                            $0
                                .lineLimit(1)
                        }
                        .accessibilityIdentifier("RecipientCell.subtitle")
                }
            }

            Spacer()
            if let trailingView {
                trailingView
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
