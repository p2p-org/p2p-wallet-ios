import CountriesAPI

extension Country: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: emoji ?? "", name: name)
    }
}
