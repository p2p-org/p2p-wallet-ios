import KeyAppUI
import SkeletonUI
import SwiftUI

struct BankTransferInfoImageCellViewItem: Identifiable {
    var id: String = UUID().uuidString
    var image: UIImage
}

extension BankTransferInfoImageCellViewItem: Renderable {
    func render() -> some View {
        BankTransferInfoImageView(image: image)
    }
}

struct BankTransferInfoImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .fixedSize()
    }
}

struct BankTransferInfoImageView_Previews: PreviewProvider {
    static var previews: some View {
        BankTransferInfoImageView(image: .accountCreationFee)
    }
}

// MARK: - Title

struct BankTransferTitleCellViewItem: Identifiable {
    var id: String { title }
    var title: String
}

extension BankTransferTitleCellViewItem: Renderable {
    func render() -> some View {
        BankTransferTitleCellView(title: title)
    }
}

struct BankTransferTitleCellView: View {
    let title: String

    var body: some View {
        Text(title)
            .apply(style: .title2, weight: .bold)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
    }
}

// MARK: - Country

struct BankTransferCountryCellViewItem: Identifiable {
    var id: String { name + flag }
    var name: String
    var flag: String
    var isLoading: Bool
}

extension BankTransferCountryCellViewItem: Renderable {
    func render() -> some View {
        BankTransferCountryCellView(name: name, flag: flag, isLoading: isLoading)
    }
}

struct BankTransferCountryCellView: View {
    let name: String
    let flag: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            flagView
                .padding(.leading, 16)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .apply(style: .text3, weight: .semibold)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .skeleton(
                        with: isLoading,
                        size: CGSize(width: 150, height: 20),
                        animated: .default
                    )
                Text(L10n.yourCountry)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.trailing, 19)
        }
        .padding(.vertical, 12)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 16, corners: .allCorners)
    }

    var flagView: some View {
        Rectangle()
            .fill(Color(Asset.Colors.smoke.color))
            .cornerRadius(radius: 24, corners: .allCorners)
            .frame(width: 48, height: 48)
            .overlay {
                Text(flag)
                    .apply(style: .title1, weight: .bold)
                    .skeleton(
                        with: isLoading,
                        size: CGSize(width: 32, height: 32),
                        animated: .default
                    )
            }
    }
}

// MARK: -

struct BankTransferInfoCountriesTextCellViewItem: Identifiable {
    var id: String = UUID().uuidString
}

extension BankTransferInfoCountriesTextCellViewItem: Renderable {
    func render() -> some View {
        BankTransferInfoCountriesTextCellView()
    }
}

struct BankTransferInfoCountriesTextCellView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text(L10n.checkTheListOfCountries + " ")
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.night.color))
            Text(L10n.here)
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.sky.color))
        }
    }
}

// MARK: - Check list of countries

struct CenterTextCellViewItem: Identifiable {
    var id: String = UUID().uuidString
    let text: String
    let style: UIFont.Style
    let color: UIColor
}

extension CenterTextCellViewItem: Renderable {
    func render() -> some View {
        CenterTextCellItemView(text: text, style: style, color: Color(color))
    }
}

struct CenterTextCellItemView: View {
    let text: String
    let style: UIFont.Style
    let color: Color

    var body: some View {
        Text(text)
            .apply(style: style)
            .multilineTextAlignment(.center)
            .foregroundColor(color)
    }
}
