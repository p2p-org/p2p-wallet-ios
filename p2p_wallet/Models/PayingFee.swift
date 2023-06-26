//
//  PayingFee.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/09/2021.
//

import Foundation
import SolanaSwift
import SolanaToken

struct PayingFee {
    enum FeeType: Equatable {
        case liquidityProviderFee
        case accountCreationFee(token: String?)
        case orderCreationFee
        case transactionFee
        case depositWillBeReturned

        var headerString: String {
            switch self {
            case .liquidityProviderFee:
                return L10n.liquidityProviderFee
            case let .accountCreationFee(token: token):
                if let token = token {
                    return L10n.accountCreation(token)
                } else {
                    return L10n.accountCreationFee
                }
            case .orderCreationFee:
                return L10n.serumOrderCreationPaidOncePerPair
            case .transactionFee:
                return L10n.networkFee
            case .depositWillBeReturned:
                return L10n.depositWillBeReturned
            }
        }
    }

    let type: FeeType
    let lamports: Lamports
    let token: Token

    let isFree: Bool
    let info: Info?

    init(
        type: FeeType,
        lamports: Lamports,
        token: Token
    ) {
        self.type = type
        self.lamports = lamports
        self.token = token
        isFree = false
        info = nil
    }

    init(
        type: FeeType,
        lamports: Lamports,
        token: Token,
        isFree: Bool,
        info: Info?
    ) {
        self.type = type
        self.lamports = lamports
        self.token = token
        self.isFree = isFree
        self.info = info
    }

    struct Info {
        let alertTitle: String
        let alertDescription: String
        let payBy: String?
    }
}

extension Array where Element == PayingFee {
    var networkFees: FeeAmount? {
        var transactionFee: UInt64?
        var accountCreationFee: UInt64?
        var depositFee: UInt64?
        for fee in self {
            switch fee.type {
            case .transactionFee:
                transactionFee = fee.lamports
            case .accountCreationFee:
                accountCreationFee = fee.lamports
            case .depositWillBeReturned:
                depositFee = fee.lamports
            default:
                break
            }
        }

        if let transactionFee = transactionFee, let accountCreationFee = accountCreationFee {
            return .init(transaction: transactionFee, accountBalances: accountCreationFee, deposit: depositFee ?? 0)
        }
        return nil
    }

    func networkFees(of token: String) -> FeeAmount? {
        let fees = filter { $0.token.symbol == token }

        var transactionFee: UInt64?
        var accountCreationFee: UInt64?
        var depositFee: UInt64?
        for fee in fees {
            switch fee.type {
            case .transactionFee:
                transactionFee = fee.lamports
            case .accountCreationFee:
                accountCreationFee = fee.lamports
            case .depositWillBeReturned:
                depositFee = fee.lamports
            default:
                break
            }
        }

        return .init(
            transaction: transactionFee ?? 0,
            accountBalances: accountCreationFee ?? 0,
            deposit: depositFee ?? 0
        )
    }

    func transactionFees(of token: String) -> Lamports {
        filter { $0.type == .transactionFee && $0.token.symbol == token }
            .reduce(Lamports(0)) { $0 + $1.lamports }
    }
}
