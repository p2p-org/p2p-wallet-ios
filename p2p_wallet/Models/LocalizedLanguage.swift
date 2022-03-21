//
//  LocalizedLanguage.swift
//  p2p_wallet
//
//  Created by Chung Tran on 12/10/2021.
//

import Foundation

struct LocalizedLanguage: Hashable, Codable, DefaultsSerializable {
    var code: String

    var localizedName: String? {
        Locale.shared.localizedString(forLanguageCode: code)
    }

    var originalName: String? {
        Locale(identifier: code).localizedString(forLanguageCode: code)
    }
}
