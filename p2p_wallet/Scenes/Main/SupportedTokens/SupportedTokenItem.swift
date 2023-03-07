//
//  SupportedTokenItem.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 07.03.2023.
//

import Foundation

enum SupportedTokenItemIcon {
    case url(URL)
    case image(UIImage)
}

protocol SupportedTokenItem: Identifiable {
    var icon: SupportedTokenItemIcon { get }

    var title: String { get }

    var subtitle: String { get }

    var availableNetwork: [SupportedTokenItemIcon] { get }

    var onTap: () -> Void { get }
}
