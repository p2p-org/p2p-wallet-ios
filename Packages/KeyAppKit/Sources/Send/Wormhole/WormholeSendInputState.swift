//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import BigInt
import Foundation
import KeyAppBusiness
import Wormhole

public enum WormholeSendInputState: Equatable {
    public typealias Service = WormholeService
    
    case initializing(input: WormholeSendInputBase)
    
    case initializingFailure(error: InitializingError)
    
    case ready(
        input: WormholeSendInputBase,
        transactions: [String],
        fees: SendFees,
        alert: WormholeSendInputAlert?
    )
    
    case calculating(newInput: WormholeSendInputBase)
    
    case error(input: WormholeSendInputBase, error: WormholeSendInputError)
    
    case unauthorized
    
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
                    return .initializingFailure(error: .getTransactionsFailure)
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
                    return .initializingFailure(error: .calculateFeeFailure)
                }
            
                return .ready(input: input, transactions: transactions, fees: fees, alert: nil)
            default:
                return self
            }
            
        case let .ready(input, _, _, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input.amount = newInput
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
                    return .error(input: input, error: .calculationFeeFailure)
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
                    return .error(input: input, error: .getTransferTransactionsFailure)
                }
                
                return .ready(input: input, transactions: transactions, fees: fees, alert: nil)
                
            case let .updateInput(newInput):
                var input = input
                input.amount = newInput
                return .calculating(newInput: input)
            default:
                return self
            }
            
        case let .error(input, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input.amount = newInput
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
        case .initializing:
            return false
        case .initializingFailure:
            return false
        case .ready:
            return false
        case .calculating:
            return true
        case .error:
            return false
        case .unauthorized:
            return false
        }
    }
}

public enum WormholeSendInputAction {
    case initialize
    case updateInput(amount: BigUInt)
    case calculate
}

public struct WormholeSendInputBase: Equatable {
    let solanaAccount: SolanaAccountsService.Account
    
    var amount: BigUInt
    
    let recipient: String
    
    let feePayer: String
    
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
