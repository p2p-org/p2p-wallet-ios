import BankTransfer

struct Industry: Identifiable {
    let emoji: String
    let title: String
    let rawValue: StrigaUserIndustry

    var id: String { rawValue.rawValue }
    var wholeName: String {
        [emoji, title].joined(separator: " ")
    }
}

extension Industry: ChooseItemSearchableItem {
    func matches(keyword: String) -> Bool {
        return title.hasPrefix(keyword) || title.contains(keyword)
    }
}

extension Industry: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: emoji, name: title)
    }
}
