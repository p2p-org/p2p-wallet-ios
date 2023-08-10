import CountriesAPI
import Foundation

extension Country: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: emoji ?? "", name: name, subtitle: nil)
    }
}

extension Region: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: (flagEmoji ?? ""), name: name, subtitle: nil)
    }
}
