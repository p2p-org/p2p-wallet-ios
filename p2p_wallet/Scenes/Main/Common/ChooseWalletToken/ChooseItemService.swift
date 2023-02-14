protocol ChooseItemService {
    var chosenTokenTitle: String { get }
    var otherTokensTitle: String { get }

    func fetchItems() async throws -> [ChooseItemListSection]
    func filterAndSort(items: [ChooseItemListSection], by keyword: String) -> [ChooseItemListSection]
}
