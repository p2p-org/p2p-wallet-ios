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
        case depositWillBeReturned

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
            case .depositWillBeReturned:
                return L10n.depositWillBeReturned
            }
        }

        var isNetworkFee: Bool {
            switch self {
            case .transactionFee, .accountCreationFee:
                return true
            default:
                return false
            }
        }
    }

    let type: FeeType
    let lamports: SolanaSDK.Lamports
    let token: SolanaSDK.Token
    var toString: (() -> String?)?

    let isFree: Bool
    let info: Info?

    init(
        type: FeeType,
        lamports: SolanaSDK.Lamports,
        token: SolanaSDK.Token,
        toString: (() -> String?)? = nil
    ) {
        self.type = type
        self.lamports = lamports
        self.token = token
        isFree = false
        self.toString = toString
        info = nil
    }

    init(
        type: FeeType,
        lamports: SolanaSDK.Lamports,
        token: SolanaSDK.Token,
        toString: (() -> String?)?,
        isFree: Bool,
        info: Info?
    ) {
        self.type = type
        self.lamports = lamports
        self.token = token
        self.toString = toString
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
    @available(*, deprecated, message: "Don't use this methods any more")
    var totalFee: (lamports: SolanaSDK.Lamports, token: SolanaSDK.Token)? {
        // exclude liquidityProviderFee
        let array = filter { $0.type != .liquidityProviderFee }

        guard !array.isEmpty,
              let token = array.first?.token
        else {
            return nil
        }

        let lamports = array.reduce(SolanaSDK.Lamports(0)) { $0 + $1.lamports }

        return (lamports: lamports, token: token)
    }

    var networkFees: SolanaSDK.FeeAmount? {
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

    func networkFees(of token: String) -> SolanaSDK.FeeAmount? {
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

        return .init(transaction: transactionFee ?? 0, accountBalances: accountCreationFee ?? 0, deposit: depositFee ?? 0)
    }

    func transactionFees(of token: String) -> SolanaSDK.Lamports {
        filter { $0.type == .transactionFee && $0.token.symbol == token }
            .reduce(SolanaSDK.Lamports(0)) { $0 + $1.lamports }
    }

    func all(ofToken tokenSymbol: String) -> SolanaSDK.Lamports? {
        filter { $0.token.symbol == tokenSymbol }.reduce(UInt64(0)) { $0 + $1.lamports }
    }
}
