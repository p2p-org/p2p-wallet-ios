//
//  Environment.swift
//  p2p_wallet
//
//  Created by Ivan on 04.07.2022.
//

import Foundation

enum Environment {
    case debug
    case test
    case release

    static var current: Environment {
        #if DEBUG
            return .debug
        #elseif TEST
            return .test
        #else
            return .release
        #endif
    }
}
