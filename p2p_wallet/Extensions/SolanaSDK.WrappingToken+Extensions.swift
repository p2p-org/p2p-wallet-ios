//
//  SolanaSDK.WrappingToken+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/04/2021.
//

import Foundation

extension SolanaSDK.WrappingToken {
    var image: UIImage? {
        // swiftlint:disable swiftgen_assets
        UIImage(named: "wrapped-by-" + rawValue)
        // swiftlint:disable swiftgen_assets
    }
}
