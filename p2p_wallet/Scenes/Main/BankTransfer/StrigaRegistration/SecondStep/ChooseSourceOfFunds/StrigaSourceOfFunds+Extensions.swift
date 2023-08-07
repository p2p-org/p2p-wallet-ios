import BankTransfer

extension StrigaSourceOfFunds {
    var title: String {
        rawValue.replacingOccurrences(of: "_", with: " ").lowercased().uppercaseFirst
    }
}

extension StrigaSourceOfFunds: Identifiable {
    public var id: String { rawValue }
}

extension StrigaSourceOfFunds: ChooseItemSearchableItem {
    func matches(keyword: String) -> Bool {
        title.hasPrefix(keyword) || title.contains(keyword)
    }
}

extension StrigaSourceOfFunds: ChooseItemRenderable {
    func render() -> TitleCellView {
        TitleCellView(title: title)
    }
}
