import KeyAppUI
import SwiftUI

struct EmojiTitleCellViewItem: Identifiable {
    let id = UUID().uuidString
    let emoji: String
    let name: String
    let subtitle: String?
}

extension EmojiTitleCellViewItem: Renderable {
    func render() -> some View {
        EmojiTitleCellView(emoji: emoji, name: name, subtitle: subtitle)
    }
}

struct EmojiTitleCellView: View {
    let emoji: String
    let name: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(uiFont: .font(of: .title1, weight: .bold))
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .apply(style: .text3)
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .apply(style: .label1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct EmojiTitleCellView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiTitleCellView(emoji: "🇫🇷", name: "France", subtitle: nil)
    }
}
