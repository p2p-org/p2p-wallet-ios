import Foundation

class FavouriteAccountsDataSource: ObservableObject {
    /// Ignore list
    @Published var favourites: [String] {
        didSet {
            Defaults.unhiddenWalletPubkey = favourites
        }
    }

    /// Favourite list
    @Published var ignores: [String] {
        didSet {
            Defaults.hiddenWalletPubkey = ignores
        }
    }

    init() {
        favourites = Defaults.unhiddenWalletPubkey
        ignores = Defaults.hiddenWalletPubkey
    }

    func markAsFavourite(key: String) {
        favourites.append(key)
        ignores = ignores.filter { $0 != key }
    }

    func markAsIgnore(key: String) {
        favourites = favourites.filter { $0 != key }
        ignores.append(key)
    }
}
