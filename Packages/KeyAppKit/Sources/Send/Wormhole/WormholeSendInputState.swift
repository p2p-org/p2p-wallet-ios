//
//  File.swift
//
//
//  Created by Giang Long Tran on 21.03.2023.
//

import BigInt
import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import OrcaSwapSwift
import SolanaSwift
import Wormhole

public enum WormholeSendInputState: Equatable {
    public typealias Service = (
        wormhole: WormholeService,
        relay: RelayService,
        relayContextManager: RelayContextManager,
        orcaSwap: OrcaSwapType
    )

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

    public func onAccept(action: WormholeSendInputAction, service: Service) async -> Self {
        switch self {
        case let .initializing(input):
            switch action {
            case .initialize:
                let fees: SendFees
                do {
                    fees = try await service.wormhole.getTransferFees(
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount.value)
                    )
                } catch {
                    return .initializingFailure(input: input, error: .getTransactionsFailure)
                }

                let solanaFees: CryptoAmount = [fees.networkFee, fees.messageAccountRent, fees.bridgeFee]
                    .compactMap { $0 }
                    .map { tokenAmount in
                        CryptoAmount(bigUIntString: tokenAmount.amount, token: SolanaToken.nativeSolana)
                    }
                    .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

                let transactions: SendTransaction
                do {
                    let feePayerAddress = try await service.relayContextManager.getCurrentContextOrUpdate()
                        .feePayerAddress
                        .base58EncodedString

                    transactions = try await service.wormhole.transferFromSolana(
                        feePayer: feePayerAddress,
                        from: input.solanaAccount.data.pubkey ?? "",
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount.value)
                    )
                } catch {
                    return .initializingFailure(input: input, error: .calculateFeePayerFailure)
                }

                return .ready(
                    input: input,
                    output: .init(feePayer: feePayerBestCandidate, transactions: transactions, fees: fees),
                    alert: nil
                )
            default:
                return self
            }

        case let .ready(input, _, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input
                    .amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token) ??
                    CryptoAmount(token: input.solanaAccount.data.token)
                return .calculating(newInput: input)
            case let .updateSolanaAccount(account):
                var input = input
                input.solanaAccount = account
                input.amount = .init(amount: input.amount.value, token: account.data.token)
                return .calculating(newInput: input)
            default:
                return self
            }

        case let .calculating(input):
            switch action {
            case .calculate:
                // Check input amount
                if input.amount > input.solanaAccount.cryptoAmount {
                    return .error(input: input, output: nil, error: .maxAmountReached)
                }

                // Get fees
                let fees: SendFees
                do {
                    fees = try await service.wormhole.getTransferFees(
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount.value)
                    )
                } catch {
                    return .error(input: input, output: nil, error: .calculationFeeFailure)
                }

                // Build transaction
                let transactions: SendTransaction
                do {
                    transactions = try await service.wormhole.transferFromSolana(
                        feePayer: input.feePayer,
                        from: input.solanaAccount.data.pubkey ?? "",
                        recipient: input.recipient,
                        mint: input.solanaAccount.data.token.address,
                        amount: String(input.amount.value)
                    )
                } catch {
                    return .error(
                        input: input,
                        output: .init(transactions: nil, fees: fees),
                        error: .getTransferTransactionsFailure
                    )
                }

                // Check fee is greater than sending amount
                var alert: WormholeSendInputAlert?
                if
                    let price = input.solanaAccount.price,
                    let inputAmountInFiat = try? input.amount.toFiatAmount(price: price)
                {
                    if inputAmountInFiat <= fees.totalInFiat {
                        alert = .feeIsMoreThanInputAmount
                    }
                }
                
                let feePayerCandidates: [SolanaAccount] = [
                    // Same account
                    input.availableAccounts.first(where: { account in
                        account.data.token.address == input.solanaAccount.data.token.address
                    }),

                    // Account with high amount in fiat
                    input.availableAccounts.sorted(by: { lhs, rhs in
                        guard
                            let lhsAmount = lhs.amountInFiat,
                            let rhsAmount = rhs.amountInFiat
                        else {
                            return false
                        }

                        return lhsAmount > rhsAmount
                    })
                    .first,

                    // Native account
                    input.availableAccounts.nativeWallet,
                ].compactMap { $0 }

                var feePayerBestCandidate: SolanaAccount?
                for feePayerCandidate in feePayerCandidates {
                    if feePayerCandidate.data.isNativeSOL {
                        if (input.amount + solanaFees) < feePayerCandidate.cryptoAmount {
                            feePayerBestCandidate = feePayerCandidate
                            break
                        }
                    } else {
                        do {
                            let feeInToken = try await service.relay.feeCalculator.calculateFeeInPayingToken(
                                orcaSwap: service.orcaSwap,
                                feeInSOL: .init(transaction: UInt64(solanaFees.value), accountBalances: 0),
                                payingFeeTokenMint: PublicKey(string: feePayerCandidate.data.token.address)
                            )

                            if (feeInToken?.total ?? 0) < (feePayerCandidate.data.lamports ?? 0) {
                                feePayerBestCandidate = feePayerCandidate
                                break
                            }
                        } catch {
                            continue
                        }
                    }
                }

                guard let feePayerBestCandidate = feePayerBestCandidate ?? input.availableAccounts.nativeWallet else {
                    return .initializingFailure(input: input, error: .calculateFeeFailure)
                }

                return .ready(
                    input: input,
                    output: .init(
                        transactions: transactions,
                        fees: fees
                    ),
                    alert: alert
                )

            case let .updateInput(newInput):
                var input = input
                input
                    .amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token) ??
                    CryptoAmount(token: input.solanaAccount.data.token)
                return .calculating(newInput: input)

            case let .updateSolanaAccount(account):
                var input = input
                input.solanaAccount = account
                input.amount = .init(amount: input.amount.value, token: account.data.token)
                return .calculating(newInput: input)
            default:
                return self
            }

        case let .error(input, _, _):
            switch action {
            case let .updateInput(newInput):
                var input = input
                input
                    .amount = CryptoAmount(floatString: newInput, token: input.solanaAccount.data.token) ??
                    CryptoAmount(token: input.solanaAccount.data.token)
                return .calculating(newInput: input)
            case let .updateSolanaAccount(account):
                var input = input
                input.solanaAccount = account
                input.amount = .init(amount: input.amount.value, token: account.data.token)
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
    public func trigger(service _: Service) async -> WormholeSendInputAction? {
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
    case updateSolanaAccount(account: SolanaAccountsService.Account)
    case calculate
}

public struct WormholeSendInputBase: Equatable {
    public var solanaAccount: SolanaAccount

    public var availableAccounts: [SolanaAccount]

    public var amount: CryptoAmount

    public let recipient: String

    public init(
        solanaAccount: SolanaAccount,
        availableAccounts: [SolanaAccount],
        amount: CryptoAmount,
        recipient: String,
        feePayer: String
    ) {
        self.solanaAccount = solanaAccount
        self.availableAccounts = availableAccounts
        self.amount = amount
        self.recipient = recipient
        self.feePayer = feePayer
    }
}

public struct WormholeSendOutputBase: Equatable {
    public let feePayer: SolanaAccount
    public let transactions: SendTransaction?
    public let fees: SendFees

    public init(feePayer: SolanaAccount, transactions: SendTransaction?, fees: SendFees) {
        self.feePayer = feePayer
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
    case calculateFeePayerFailure
    case getTransactionsFailure
    case missingArguments
}

public enum WormholeSendInputAlert: Equatable {
    case feeIsMoreThanInputAmount
}
