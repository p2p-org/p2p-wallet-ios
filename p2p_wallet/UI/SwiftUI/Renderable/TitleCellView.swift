import KeyAppUI
import SwiftUI

struct TitleCellViewItem: Identifiable {
    var id = UUID().uuidString
    let title: String
}

extension TitleCellViewItem: Renderable {
    func render() -> some View {
        TitleCellView(title: title)
    }
}

struct TitleCellView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color(asset: Asset.Colors.night))
                .apply(style: .text3)
                .padding(.vertical, 6)

            Spacer()
        }
    }
}

struct TitleCellView_Previews: PreviewProvider {
    static var previews: some View {
        TitleCellView(title: "France")
    }
}
