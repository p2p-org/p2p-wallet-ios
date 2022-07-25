import CountriesAPI
import Foundation

struct SelectableCountry: Hashable {
    let value: Country
    var isSelected: Bool = false
}

extension Array where Element == SelectableCountry {
    func filteredAndSorted(byKeyword keyword: String) -> Self {
        var countries = self
        if !keyword.isEmpty {
            let keyword = keyword.lowercased()
            countries = countries
                .filter { country in
                    country.value.name.lowercased().contains(keyword) ||
                        country.value.code.lowercased().contains(keyword) ||
                        keyword.contains(country.value.emoji ?? "") ||
                        country.value.dialCode.contains(keyword)
                }
                .sorted(by: { c1, c2 in
                    let name1 = c1.value.name.lowercased()
                    let name2 = c2.value.name.lowercased()

                    // Sort:
                    // First by name that starts with keyword, then by alphabet

                    // if both name start with keyword or both name do not start with keyword, compare by alphabet
                    if (name1.starts(with: keyword) && name2.starts(with: keyword)) ||
                        (!name1.starts(with: keyword) && !name2.starts(with: keyword))
                    {
                        return name1 < name2
                    }

                    // else
                    return name1.starts(with: keyword)
                })
        }
        return countries
    }
}
