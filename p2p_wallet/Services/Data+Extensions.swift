//
//  Data+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/26/20.
//

import Foundation
import Base58Swift

extension Data {
    var base58EncodedString: String {
        Base58.base58Encode([UInt8](self))
    }
}
