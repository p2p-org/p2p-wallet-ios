//
//  PayingFee.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/09/2021.
//

import Foundation

struct PayingFee {
    enum FeeType {
        case liquidityProviderFee
        case accountCreationFee
        case orderCreationFee
        case transactionFee
    }
    
    let type: FeeType
    let lamports: SolanaSDK.Lamports
    let token: SolanaSDK.Token
    var toString: (() -> String?)?
    
    var headerString: String {
        switch type {
        case .liquidityProviderFee:
            return L10n.liquidityProviderFee
        case .accountCreationFee:
            return L10n.accountCreationFee
        case .orderCreationFee:
            return L10n.serumOrderCreationPaidOncePerPair
        case .transactionFee:
            return L10n.transactionFee
        }
    }
}

extension Array where Element == PayingFee {
    var totalFee: (lamports: SolanaSDK.Lamports, token: SolanaSDK.Token)? {
        // exclude liquidityProviderFee
        let array = self.filter {$0.type != .liquidityProviderFee}
        
        guard !array.isEmpty,
              let token = array.first?.token
        else {
            return nil
        }
        
        let lamports = reduce(SolanaSDK.Lamports(0), {$0 + $1.lamports})
        
        return (lamports: lamports, token: token)
    }
}
