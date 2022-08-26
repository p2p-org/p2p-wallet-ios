import CountriesAPI
import Foundation

struct SelectableCountry: Hashable {
    let value: Country
    var isSelected: Bool = false
    var isEmpty: Bool = false
}

extension Array where Element == SelectableCountry {
    func filteredAndSorted(byKeyword keyword: String = "") -> Self {
        var countries = self
        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            countries = countries
                .filter { country in
                    // Filter only countries which name or dialCode starts with keyword
                    var dialCode = country.value.dialCode
                    if keyword.first != "+" {
                        dialCode.removeFirst()
                    }
                    return country.value.name.lowercased().starts(with: keyword) ||
                        country.value.dialCode.starts(with: keyword) ||
                        dialCode.starts(with: keyword)
                }
        }
        return countries.sorted(by: { $0.value.name < $1.value.name })
    }
}
