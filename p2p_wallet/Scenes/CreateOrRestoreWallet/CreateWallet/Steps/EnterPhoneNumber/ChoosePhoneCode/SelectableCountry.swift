import CountriesAPI
import Foundation

struct SelectableCountry: Hashable {
    let value: Country
    var isSelected: Bool = false
}

extension Array where Element == SelectableCountry {
    func filteredByKeyword(keyword: String) -> Self {
        var countries = self
        if !keyword.isEmpty {
            let searchText = keyword.lowercased()
            countries = countries.filter { country in
                country.value.name.lowercased().contains(searchText) ||
                    country.value.code.contains(searchText) ||
                    searchText.contains(country.value.emoji ?? "")
            }
        }
        return countries
    }
}
