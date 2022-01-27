//
//  PayingFee.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/09/2021.
//

import Foundation

struct PayingFee {
    enum FeeType: Equatable {
        case liquidityProviderFee
        case accountCreationFee(token: String?)
        case orderCreationFee
        case transactionFee
        
        var headerString: String {
            switch self {
            case .liquidityProviderFee:
                return L10n.liquidityProviderFee
            case let .accountCreationFee(token: token):
                if let token = token {
                    return "\(token) \(L10n.accountCreationFee)"
                } else {
                    return L10n.accountCreationFee
                }
            case .orderCreationFee:
                return L10n.serumOrderCreationPaidOncePerPair
            case .transactionFee:
                return L10n.transactionFee
            }
        }
    }
    
    let type: FeeType
    let lamports: SolanaSDK.Lamports
    let token: SolanaSDK.Token
    var toString: (() -> String?)?
}

extension Array where Element == PayingFee {
    func transactionFees(of token: String) -> SolanaSDK.Lamports {
        filter {$0.type == .transactionFee && $0.token.symbol == token}
            .reduce(SolanaSDK.Lamports(0), {$0 + $1.lamports})
    }
}
