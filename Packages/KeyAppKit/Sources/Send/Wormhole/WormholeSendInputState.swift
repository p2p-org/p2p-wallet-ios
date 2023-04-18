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
                // Check input amount and account amount
                if input.solanaAccount.cryptoAmount.value == 0 {
                    return .error(input: input, output: nil, error: .insufficientInputAmount)
                }
                if input.amount > input.solanaAccount.cryptoAmount {
                    return .error(input: input, output: nil, error: .maxAmountReached)
                }

                guard let relayContext = service.relayContextManager.currentContext else {
                    return .error(input: input, output: nil, error: .missingRelayContext)
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

                // Total fee in SOL
                let feeInSolanaNetwork: CryptoAmount = [fees.networkFee, fees.bridgeFee]
                    .compactMap { $0 }
                    .map { tokenAmount in
                        CryptoAmount(bigUIntString: tokenAmount.amount, token: SolanaToken.nativeSolana)
                    }
                    .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

                // Select best wallet for paying fee.
                let feePayerBestCandidate: SolanaAccount
                let feeAmountForBestCandidate: CryptoAmount
                do {
                    (feePayerBestCandidate, feeAmountForBestCandidate) = try await WormholeSendInputLogic
                        .autoSelectFeePayer(
                            fee: feeInSolanaNetwork,
                            accountCreationFee: fees.messageAccountRent?
                                .asCryptoAmount ?? .init(token: SolanaToken.nativeSolana),
                            selectedAccount: input.solanaAccount,
                            availableAccounts: input.availableAccounts,
                            transferAmount: input.amount,
                            feeCalculator: service.relay.feeCalculator,
                            orcaSwap: service.orcaSwap,
                            minSOLBalance: CryptoAmount(
                                uint64: relayContext.minimumRelayAccountBalance,
                                token: SolanaToken.nativeSolana
                            ),
                            relayContext: relayContext
                        )
                } catch {
                    return .error(
                        input: input,
                        output: .init(
                            feePayer: nil,
                            feePayerAmount: nil,
                            transactions: nil,
                            fees: fees,
                            relayContext: relayContext
                        ),
                        error: .calculationFeePayerFailure
                    )
                }

                // Check
                let insufficientState = WormholeSendInputState.error(
                    input: input,
                    output: .init(
                        feePayer: feePayerBestCandidate,
                        feePayerAmount: feeAmountForBestCandidate,
                        transactions: nil,
                        fees: fees,
                        relayContext: relayContext
                    ),
                    error: .insufficientInputAmount
                )

                if feePayerBestCandidate.data.token.address == input.solanaAccount.data.token.address {
                    // Fee payer is equal to selected account
                    if input.amount + feeAmountForBestCandidate > input.solanaAccount.cryptoAmount {
                        return insufficientState
                    }
                } else {
                    // Fee payer isn't equal to selected account
                    if feeAmountForBestCandidate > feePayerBestCandidate.cryptoAmount {
                        return insufficientState
                    }
                }

                // Check fee is greater than sending amount
                var alert: WormholeSendInputAlert?
                if fees.resultAmount == nil {
                    return .error(
                        input: input,
                        output: .init(
                            feePayer: feePayerBestCandidate,
                            feePayerAmount: feeAmountForBestCandidate,
                            transactions: nil,
                            fees: fees,
                            relayContext: relayContext
                        ),
                        error: .feeIsMoreThanInputAmount
                    )
                }

                // Build transaction
                let transactions: SendTransaction
                do {
                    let feePayerAddress = relayContext.feePayerAddress.base58EncodedString

                    // Not (Native sol and networkFee > 0)
                    let needToUseRelay: Bool = !feePayerBestCandidate.data.isNativeSOL

                    let mint: String? = input.solanaAccount.data.token.isNative ? nil : input.solanaAccount.data.token
                        .address

                    transactions = try await service.wormhole.transferFromSolana(
                        feePayer: feePayerAddress,
                        from: input.solanaAccount.data.pubkey ?? "",
                        recipient: input.recipient,
                        mint: mint,
                        amount: String(input.amount.value),
                        needToUseRelay: needToUseRelay
                    )
                } catch {
                    return .error(
                        input: input,
                        output: .init(
                            feePayer: nil,
                            feePayerAmount: nil,
                            transactions: nil,
                            fees: fees,
                            relayContext: relayContext
                        ),
                        error: .getTransferTransactionsFailure
                    )
                }

                return .ready(
                    input: input,
                    output: .init(
                        feePayer: feePayerBestCandidate,
                        feePayerAmount: feeAmountForBestCandidate,
                        transactions: transactions,
                        fees: fees,
                        relayContext: relayContext
                    ),
                    alert: alert
                )

            case let .updateInput(newInput):
                var input = input

                input.amount = CryptoAmount(
                    floatString: newInput,
                    token: input.solanaAccount.data.token
                ) ?? CryptoAmount(
                    token: input.solanaAccount.data.token
                )

                return .calculating(newInput: input)

            case let .updateSolanaAccount(account):
                var input = input
                input.solanaAccount = account
                input.amount = .init(amount: input.amount.value, token: account.data.token)
                return .calculating(newInput: input)
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
            }

        case let .initializingFailure(input, error):
            return self
        }
    }
}

extension WormholeSendInputState: AutoTriggerState {
    public func trigger(service _: Service) async -> WormholeSendInputAction? {
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
        case .initializingFailure, .ready, .error:
            return false
        case .calculating:
            return true
        }
    }
}
