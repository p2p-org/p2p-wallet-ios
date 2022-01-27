//
//  DAppChannelError.swift
//  p2p_wallet
//
//  Created by Chung Tran on 26/11/2021.
//

import Foundation

enum DAppChannelError {
    static var canNotFindWalletAddress = Self.createError(code: 400, message: "Can not find wallet address")
    static var invalidTransaction = Self.createError(code: 400, message: "Invalid transactions")
    static var unauthorized = Self.createError(code: 400, message: "Unauthorized")
    
    private static func createError(code: Int, message: String) -> NSError {
        NSError(domain: "DAppChannel", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
