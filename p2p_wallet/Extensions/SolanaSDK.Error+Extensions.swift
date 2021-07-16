//
//  SolanaSDK.Error+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 16/07/2021.
//

import Foundation
import FeeRelayerSwift

extension SolanaSDK.Error: FeeRelayerError {
    public static func createInvalidResponseError(code: Int, message: String) -> SolanaSDK.Error {
        .invalidResponse(.init(code: code, message: message, data: nil))
    }
}
