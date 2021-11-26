//
//  DAppChannelError.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Foundation

enum DAppChannelError {
    static var platformIsNotReady = Self.createError(code: 400, message: "Platform is not ready")
    static var canNotFindWalletAddress = Self.createError(code: 400, message: "Can not find wallet address")
    
    private static func createError(code: Int, message: String) -> NSError {
        NSError(domain: "DAppChannel", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
