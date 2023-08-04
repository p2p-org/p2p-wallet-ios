import CountriesAPI
import Foundation

extension Country: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: emoji ?? "", name: name, subtitle: nil)
    }
}

extension Region: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: (flagEmoji ?? "").decodeHTMLEntities() ?? "", name: name, subtitle: nil)
    }
}
