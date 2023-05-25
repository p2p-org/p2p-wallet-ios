import Combine
import CountriesAPI
import Foundation

extension Country: ChooseItemSearchableItem {
    public var id: String { name }

    func matches(keyword: String) -> Bool {
        name.lowercased().hasPrefix(keyword.lowercased()) || name.lowercased().contains(keyword.lowercased())
    }
}
