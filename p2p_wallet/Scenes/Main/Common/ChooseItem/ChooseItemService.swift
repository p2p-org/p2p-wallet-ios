import Combine
import KeyAppKitCore

protocol ChooseItemService {
    var otherTitle: String { get }
    var chosenTitle: String { get }
    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> { get }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection]
    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection]
}
