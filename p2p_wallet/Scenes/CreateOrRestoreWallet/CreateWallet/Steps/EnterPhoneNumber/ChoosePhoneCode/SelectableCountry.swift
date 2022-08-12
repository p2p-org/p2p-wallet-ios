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
        if keyword.isEmpty {
            return countries.sorted(by: { $0.value.name < $1.value.name })
        }
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
                .sorted(by: { c1, c2 in
                    let name1 = c1.value.name.lowercased()
                    let name2 = c2.value.name.lowercased()

                    var dialCode1 = c1.value.dialCode
                    var dialCode2 = c2.value.dialCode
                    if keyword.first != "+" {
                        dialCode1.removeFirst()
                        dialCode2.removeFirst()
                    }

                    // Sort:

                    // First by name that starts with keyword
                    // Compare names by alphabet
                    if name1.starts(with: keyword), name2.starts(with: keyword) {
                        return name1 < name2
                    }

                    // Second by dialCode that starts with keyword
                    // Compare by alphabet
                    if dialCode1.starts(with: keyword), dialCode2.starts(with: keyword) {
                        return dialCode1 < dialCode2
                    }

                    // else by alphabet
                    return name1 < name2
                })
        }
        return countries
    }
}
