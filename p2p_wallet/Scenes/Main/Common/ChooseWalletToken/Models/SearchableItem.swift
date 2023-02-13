protocol SearchableItem where Self: Identifiable {
    var id: String { get }
    func searchPattern(_ keyword: String) -> Bool
}
