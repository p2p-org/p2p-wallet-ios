import SwiftUI
import KeyAppUI

struct BankTransferInfoImageViewCellItem: Identifiable {
    var id: String = UUID().uuidString
    var image: UIImage
}

extension BankTransferInfoImageViewCellItem: Renderable {
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

struct BankTransferTitleCellItem: Identifiable {
    var id: String { title }
    var title: String
}

extension BankTransferTitleCellItem: Renderable {
    func render() -> some View {
        BankTransferTitleCellView(title: title)
    }
}

struct BankTransferTitleCellView: View {
    let title: String

    var body: some View {
        Text(title)
            .fontWeight(.bold)
            .apply(style: .title2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }
}

// MARK: - Country

struct BankTransferCountryCellItem: Identifiable {
    var id: String { name + flag }
    var name: String
    var flag: String
}

extension BankTransferCountryCellItem: Renderable {
    func render() -> some View {
        BankTransferCountryCellView(name: name, flag: flag)
    }
}

struct BankTransferCountryCellView: View {
    let name: String
    let flag: String

    var body: some View {
        HStack(spacing: 10) {
            flagView
                .padding(.leading, 14)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Text(L10n.yourCountry)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            Spacer()
            Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.trailing, 19)
        }
        .padding(.vertical, 10)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 12, corners: .allCorners)
    }

    var flagView: some View {
        Text(flag)
            .fontWeight(.bold)
            .apply(style: .title1)
    }
}

// MARK: -

struct BankTransferInfoCountriesTextCellItem: Identifiable {
    var id: String = UUID().uuidString
}

extension BankTransferInfoCountriesTextCellItem: Renderable {
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

struct CenterTextCellItem: Identifiable {
    var id: String = UUID().uuidString
    let text: String
    let style: UIFont.Style
    let color: Color
}

extension CenterTextCellItem: Renderable {
    func render() -> some View {
        CenterTextCellItemView(text: text, style: style, color: color)
    }
}

struct CenterTextCellItemView: View {
    let text: String
    let style: UIFont.Style
    let color: Color

    var body: some View {
        Text(text)
            .apply(style: style)
            .foregroundColor(color)
    }
}

