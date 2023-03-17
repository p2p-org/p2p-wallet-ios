protocol ChooseItemService {
    var chosenTokenTitle: String { get }
    var otherTokensTitle: String { get }

    func fetchItems() async throws -> [ChooseItemListSection]
    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection]
    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection]
}
