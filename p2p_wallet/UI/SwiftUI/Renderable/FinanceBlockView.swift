import KeyAppUI
import SwiftUI

struct FinanceBlockView: View {
    let leadingItem: any Renderable
    let centerItem: any Renderable
    let trailingItem: any Renderable

    var leadingView: some View {
        AnyView(leadingItem.render())
    }

    var centerView: some View {
        AnyView(centerItem.render())
    }

    var trailingView: some View {
        AnyView(trailingItem.render())
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                leadingView
                centerView
            }
            .padding(.leading, 16)
            Spacer()
            trailingView
                .padding(.trailing, 16)
        }
        .padding(.vertical, 12)
        .background(.white)
    }
}

struct FinanceBlockView_Previews: PreviewProvider {
    static var previews: some View {
        FinanceBlockView(
            leadingItem: FinanceBlockLeadingItem(
                image: .image(.iconUpload),
                iconSize: CGSize(width: 50, height: 50),
                isWrapped: false
            ),
            centerItem: FinancialBlockCenterItem(
                title: "renderable.title",
                subtitle: "renderable.subtitle"
            ),
            trailingItem: ListSpacerCellViewItem(height: 0, backgroundColor: .clear)
        )
    }
}

// MARK: - Leading

struct FinanceBlockLeadingItem: Renderable {
    typealias ViewType = FinanceBlockLeadingView
    var id: String = UUID().uuidString

    // TODO: Get rid of AccountIcon
    var image: AccountIcon
    var iconSize: CGSize
    var isWrapped: Bool

    func render() -> FinanceBlockLeadingView {
        FinanceBlockLeadingView(item: self)
    }
}

struct FinanceBlockLeadingView: View {
    let item: FinanceBlockLeadingItem

    var body: some View {
        var anURL: URL?
        var aSeed: String?
        var anImage: UIImage?
        switch item.image {
        case let .url(url):
            anURL = url
        case let .image(image):
            anImage = image
        case let .random(seed):
            aSeed = seed
        }
        return CoinLogoImageViewRepresentable(
            size: item.iconSize.width,
            args: .manual(
                preferredImage: anImage,
                url: anURL,
                key: aSeed ?? "",
                wrapped: item.isWrapped
            )
        )
        .frame(width: item.iconSize.width, height: item.iconSize.height)
    }
}

// MARK: - Center

struct FinancialBlockCenterItem: Renderable {
    typealias ViewType = FinancialBlockCenterView
    var id: String = UUID().uuidString

    var title: String?
    var subtitle: String?

    func render() -> FinancialBlockCenterView {
        FinancialBlockCenterView(item: self)
    }
}

struct FinancialBlockCenterView: View {
    let item: FinancialBlockCenterItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = item.title {
                Text(title)
                    .apply(style: .text2)
                    .foregroundColor(Color(Asset.Colors.night.color))
            }
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
        }
    }
}

// MARK: - Trailing

struct FinancialBlockTrailingItem: Renderable {
    typealias ViewType = FinancialBlockTrailingView

    var id: String = UUID().uuidString
    var isLoading: Bool
    var detail: AccountDetail
    var onButtonTap: (() -> Void)?

    func render() -> FinancialBlockTrailingView {
        FinancialBlockTrailingView(item: self)
    }
}

struct FinancialBlockTrailingView: View {
    let item: FinancialBlockTrailingItem

    var body: some View {
        switch item.detail {
        case let .text(text):
            Text(text)
                .fontWeight(.semibold)
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.night.color))
        case let .button(text, enabled):
            NewTextButton(
                title: text,
                size: .small,
                style: .primaryWhite,
                isEnabled: enabled,
                isLoading: item.isLoading,
                action: { item.onButtonTap?() }
            )
        }
    }
}
