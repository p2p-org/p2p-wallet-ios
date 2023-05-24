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
            .resizable()
    }
}

struct BankTransferInfoImageView_Previews: PreviewProvider {
    static var previews: some View {
        BankTransferInfoImageView(image: .accountCreationFee)
    }
}

// MARK: - Title

struct BankTransferTitleCellItem: Identifiable {
    var id: String = UUID().uuidString
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
    }
}

// MARK: - Country

struct BankTransferCountryCellItem: Identifiable {
    var id: String = UUID().uuidString
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
            VStack(alignment: .leading, spacing: 4) {
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
                .padding(.trailing, 25)
        }
        .padding(.vertical, 12)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(radius: 12, corners: .allCorners)
        .padding(.horizontal, 20)
    }

    var flagView: some View {
        Text(flag)
            .fontWeight(.bold)
            .apply(style: .title1)
    }
}

// MARK: -

//struct BankTransferPoweredStrigaCellItem: Identifiable {
//    var id: String = UUID().uuidString
//}
//
//extension BankTransferPoweredStrigaCellItem: Renderable {
//    func render() -> some View {
//        BankTransferPoweredStrigaCellView()
//    }
//}
//
//struct BankTransferPoweredStrigaCellView: View {
//    var body: some View {
//        Text(L10n.poweredByStriga)
//            .apply(style: .text3)
//            .foregroundColor(<#T##color: Color?##Color?#>)
//    }
//}

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

