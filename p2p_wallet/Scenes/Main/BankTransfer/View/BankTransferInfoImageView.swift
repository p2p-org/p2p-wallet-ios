import SwiftUI
import KeyAppUI

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
            .fontWeight(.bold)
            .apply(style: .title2)
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
}

extension BankTransferCountryCellViewItem: Renderable {
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
    let color: Color
}

extension CenterTextCellViewItem: Renderable {
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
            .multilineTextAlignment(.center)
            .foregroundColor(color)
    }
}

