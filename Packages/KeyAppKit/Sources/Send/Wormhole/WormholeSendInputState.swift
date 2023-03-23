//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import BigInt
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Wormhole

public enum WormholeSendInputState: Equatable {
    public typealias Service = WormholeService
    
    case unauthorized
    
    case initializing(
        input: WormholeSendInputBase
    )
    
    case initializingFailure(
        input: WormholeSendInputBase?,
        error: InitializingError
    )
    
    case ready(
        input: WormholeSendInputBase,
        output: WormholeSendOutputBase,
        alert: WormholeSendInputAlert?
    )
    
    case calculating(
        newInput: WormholeSendInputBase
    )
    
    case error(
        input: WormholeSendInputBase,
        output: WormholeSendOutputBase?,
        error: WormholeSendInputError
    )
    
    public func onAccept(action: WormholeSendInputAction, service: WormholeService) async -> Self {
        switch self {
        case let .initializing(input):
            switch action {
            case .initialize:
                let fees: SendFees
                do {
                    fees = try await service.getTransferFees(
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount)
                    )
                } catch {
                    return .initializingFailure(input: input, error: .getTransactionsFailure)
                }
                
                let transactions: [String]
                do {
                    transactions = try await service.transferFromSolana(
                        feePayer: input.feePayer,
                        from: input.solanaAccount.data.pubkey ?? "",
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount)
                    )
                } catch {
                    return .initializingFailure(input: input, error: .calculateFeeFailure)
                }
            
                return .ready(
                    input: input,
                    output: .init(transactions: transactions, fees: fees),
                    alert: nil
                )
            default:
                return self
            }
            
        case let .ready(input, _, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input.amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token)?.value ?? 0
                return .calculating(newInput: input)
            default:
                return self
            }
            
        case let .calculating(input):
            switch action {
            case .calculate:
                let fees: SendFees
                do {
                    fees = try await service.getTransferFees(
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount)
                    )
                } catch {
                    return .error(input: input, output: nil, error: .calculationFeeFailure)
                }
                
                let transactions: [String]
                do {
                    transactions = try await service.transferFromSolana(
                        feePayer: input.feePayer,
                        from: input.solanaAccount.data.pubkey ?? "",
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount)
                    )
                } catch {
                    return .error(
                        input: input,
                        output: .init(transactions: [], fees: fees),
                        error: .getTransferTransactionsFailure
                    )
                }
                
                return .ready(
                    input: input,
                    output: .init(
                        transactions: transactions,
                        fees: fees
                    ),
                    alert: nil
                )
                
            case let .updateInput(newInput):
                var input = input
                input.amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token)?.value ?? 0
                return .calculating(newInput: input)
            default:
                return self
            }
            
        case let .error(input, _, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input.amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token)?.value ?? 0
                return .calculating(newInput: input)
            case .calculate:
                return .calculating(newInput: input)
            default:
                return self
            }
        default:
            return self
        }
    }
}

extension WormholeSendInputState: AutoTriggerState {
    public func trigger(service: WormholeService) async -> WormholeSendInputAction? {
        switch self {
        case .initializing:
            return .initialize
        case .calculating:
            return .calculate
        default:
            return nil
        }
    }
}

extension WormholeSendInputState: CancableState {
    public func isCancable() -> Bool {
        switch self {
        case .initializing, .initializingFailure, .ready, .unauthorized, .error:
            return false
        case .calculating:
            return true
        }
    }
}

public enum WormholeSendInputAction {
    case initialize
    case updateInput(amount: String)
    case calculate
}

public struct WormholeSendInputBase: Equatable {
    public let solanaAccount: SolanaAccountsService.Account
    
    public var amount: BigUInt
    
    public let recipient: String
    
    public let feePayer: String
    
    public init(
        solanaAccount: SolanaAccountsService.Account,
        amount: BigUInt,
        recipient: String,
        feePayer: String
    ) {
        self.solanaAccount = solanaAccount
        self.amount = amount
        self.recipient = recipient
        self.feePayer = feePayer
    }
}

public struct WormholeSendOutputBase: Equatable {
    public let transactions: [String]
    public let fees: SendFees
    
    public init(transactions: [String], fees: SendFees) {
        self.transactions = transactions
        self.fees = fees
    }
}

public enum WormholeSendInputError: Equatable {
    case calculationFeeFailure
    case getTransferTransactionsFailure
    
    case insufficientInputAmount

    case maxAmountReached
    
    case initializationFailure
}

public enum InitializingError: Error, Equatable {
    case calculateFeeFailure
    case getTransactionsFailure
    case missingArguments
}

public enum WormholeSendInputAlert: Equatable {
    case feeIsMoreThanInputAmount
}
