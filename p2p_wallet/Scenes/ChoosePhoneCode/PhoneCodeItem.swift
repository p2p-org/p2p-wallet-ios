import CountriesAPI

struct PhoneCodeItem {
    let id: String
    let country: Country

    init(country: Country) {
        id = country.id
        self.country = country
    }

    init?(country: Country?) {
        if let country {
            id = country.id
            self.country = country
        } else {
            return nil
        }
    }
}

extension PhoneCodeItem: ChooseItemSearchableItem {
    func matches(keyword: String) -> Bool {
        country.matches(keyword: keyword)
    }
}

extension PhoneCodeItem: ChooseItemRenderable {
    func render() -> EmojiTitleCellView {
        EmojiTitleCellView(emoji: country.emoji ?? "", name: country.name, subtitle: country.dialCode)
    }
}

extension PhoneCodeItem: Equatable, Hashable {
    static func == (lhs: PhoneCodeItem, rhs: PhoneCodeItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
