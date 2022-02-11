//
//  PayingToken.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/08/2021.
//

enum PayingToken: String, CaseIterable {
    case nativeSOL
    case transactionToken
    
    var description: String {
        switch self {
        case .nativeSOL:
            return L10n.nativeSolanaToken
        case .transactionToken:
            return L10n.transactionToken
        }
    }
}