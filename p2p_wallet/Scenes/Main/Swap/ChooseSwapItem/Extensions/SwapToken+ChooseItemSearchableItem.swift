extension SwapToken: ChooseItemSearchableItem {
    var id: String {
        token.mintAddress
    }

    func matches(keyword: String) -> Bool {
        token.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
            token.symbol.lowercased().contains(keyword.lowercased()) ||
            token.name.lowercased().hasPrefix(keyword.lowercased()) ||
            token.name.lowercased().contains(keyword.lowercased()) ||
            token.mintAddress.lowercased().hasPrefix(keyword.lowercased())
    }
}
