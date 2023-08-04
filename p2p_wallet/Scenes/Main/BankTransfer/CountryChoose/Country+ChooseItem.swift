import Combine
import CountriesAPI
import Foundation

extension Country: ChooseItemSearchableItem {
    public var id: String { name }

    func matches(keyword: String) -> Bool {
        name.lowercased().hasPrefix(keyword.lowercased())
    }
}

extension Region: ChooseItemSearchableItem {
    public var id: String { alpha2 }

    func matches(keyword: String) -> Bool {
        name.lowercased().hasPrefix(keyword.lowercased())
    }
}
