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

