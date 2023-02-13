extension SwapToken: SearchableItem {
    var id: String {
        jupiterToken.address
    }

    func searchPattern(_ keyword: String) -> Bool {
        jupiterToken.symbol.lowercased().hasPrefix(keyword.lowercased()) ||
        jupiterToken.symbol.lowercased().contains(keyword.lowercased()) ||
        jupiterToken.name.lowercased().hasPrefix(keyword.lowercased()) ||
        jupiterToken.name.lowercased().contains(keyword.lowercased())
    }
}
