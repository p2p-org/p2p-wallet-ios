import CountriesAPI
import Foundation

struct SelectableCountry: Hashable, Identifiable {
    let value: Country
    var isSelected = false
    var isEmpty = false

    var id: String {
        "\(value.dialCode) \(value.code)"
    }
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
                        dialCode.starts(with: keyword) ||
                        country.value.name.lowercased().split(separator: " ")
                        .map { $0.starts(with: keyword) }.contains(true)
                }
        }
        return countries.sorted(by: { $0.value.name < $1.value.name })
    }
}
