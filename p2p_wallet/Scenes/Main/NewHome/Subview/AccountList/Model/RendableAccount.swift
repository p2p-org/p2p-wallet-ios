//
//  RendableAccount.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 03.03.2023.
//

import Foundation

protocol RendableAccount: Identifiable where ID == String {
    var id: String { get }
    
    var icon: AccountIcon { get }

    var wrapped: Bool { get }

    var title: String { get }

    var subtitle: String { get }

    var detail: AccountDetail { get }

    var extraAction: AccountExtraAction? { get }

    var tags: AccountTags { get }

    var onTap: (() -> Void)? { get }
}

struct AccountTags: OptionSet {
    let rawValue: Int

    static let favourite = AccountTags(rawValue: 1 << 0)
    static let ignore = AccountTags(rawValue: 1 << 1)
}

enum AccountExtraAction {
    case visiable(action: () -> Void)
}

enum AccountDetail {
    case text(String)
    case button(label: String, action: (() -> Void)?)
}

enum AccountIcon {
    case image(UIImage)
    case url(URL)
    case random(seed: String)
}

extension RendableAccount {
    var isInIgnoreList: Bool {
        tags.contains(.ignore)
    }
}
