//
//  WrappingToken+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation
import SolanaSwift

extension WrappingToken {
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
//        UIImage(named: "wrapped-by-" + rawValue)
        // swiftlint:enable swiftgen_assets
        UIImage.wrappedToken
    }
}
