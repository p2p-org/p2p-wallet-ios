protocol ChooseItemSearchableItem where Self: Identifiable {
    var id: String { get }

    func matches(keyword: String) -> Bool
}
