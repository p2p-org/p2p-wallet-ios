import KeyAppUI
import SwiftUI

struct EmojiTitleCellViewItem: Identifiable {
    var id = UUID().uuidString
    let emoji: String
    let name: String
}

extension EmojiTitleCellViewItem: Renderable {
    func render() -> some View {
        EmojiTitleCellView(emoji: emoji, name: name)
    }
}

struct EmojiTitleCellView: View {
    let emoji: String
    let name: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(uiFont: .font(of: .title1, weight: .bold))
            Text(name)
                .foregroundColor(Color(Asset.Colors.night.color))
                .apply(style: .text3)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct EmojiTitleCellView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiTitleCellView(emoji: "🇫🇷", name: "France")
    }
}
