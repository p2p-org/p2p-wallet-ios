//
//  SystemVersion.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/03/2021.
//

import Foundation

struct SystemVersion {
    static func isIOS13() -> Bool {
        let os = ProcessInfo().operatingSystemVersion
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case let (x, _, _) where x == 13:
            return true
        default:
            return false
        }
    }
}
