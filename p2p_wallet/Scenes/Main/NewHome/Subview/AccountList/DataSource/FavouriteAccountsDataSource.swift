//
//  IgnoreAccountsStore.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

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

extension FavouriteAccountsDataSource {
    /// This helper method detects account, that should be in hidden section
    static func shouldInHiddenList(pubkey: String?, hideZeroBalance: Bool, amount: UInt64, favourites: [String], ignores: [String]) -> Bool {
        guard let pubkey = pubkey else { return false }
        if ignores.contains(pubkey) {
            return true
        } else if favourites.contains(pubkey) {
            return false
        } else if hideZeroBalance, amount == 0 {
            return true
        }
        return false
    }
}
