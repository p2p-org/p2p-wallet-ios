//
//  ClipboardManager.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2021.
//

import Foundation
import UIKit

protocol ClipboardManagerType {
    func copyToClipboard(_ string: String)
    func stringFromClipboard() -> String?
}

class ClipboardManager: ClipboardManagerType {
    func copyToClipboard(_ string: String) {
        // swiftlint:disable clipboard_direct_api
        UIPasteboard.general.string = string
        // swiftlint:enable clipboard_direct_api
    }

    func stringFromClipboard() -> String? {
        // swiftlint:disable clipboard_direct_api
        UIPasteboard.general.string
        // swiftlint:enable clipboard_direct_api
    }
}
