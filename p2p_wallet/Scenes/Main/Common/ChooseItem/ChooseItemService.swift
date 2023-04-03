import Combine
import KeyAppKitCore

protocol ChooseItemService {
    var otherTokensTitle: String { get }
    var state: AnyPublisher<AsyncValueState<[ChooseItemListSection]>, Never> { get }

    func sort(items: [ChooseItemListSection]) -> [ChooseItemListSection]
    func sortFiltered(by keyword: String, items: [ChooseItemListSection]) -> [ChooseItemListSection]
}
