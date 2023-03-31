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

                // Total fee in SOL
                let feeInSolanaNetwork: CryptoAmount = [fees.networkFee, fees.messageAccountRent, fees.bridgeFee]
                    .compactMap { $0 }
                    .map { tokenAmount in
                        CryptoAmount(bigUIntString: tokenAmount.amount, token: SolanaToken.nativeSolana)
                    }
                    .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

                // Select best wallet for paying fee.
                let feePayerBestCandidate: SolanaAccount
                do {
                    feePayerBestCandidate = try await WormholeSendInputLogic.autoSelectFeePayer(
                        fee: feeInSolanaNetwork,
                        selectedAccount: input.solanaAccount,
                        availableAccounts: input.availableAccounts,
                        transferAmount: input.amount,
                        feeCalculator: service.relay.feeCalculator,
                        orcaSwap: service.orcaSwap
                    )
                } catch {
                    return .error(
                        input: input,
                        output: .init(
                            feePayer: nil,
                            transactions: nil,
                            fees: fees
                        ),
                        error: .calculationFeePayerFailure
                    )
                }

                // Build transaction
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
                    return .error(
                        input: input,
                        output: .init(
                            feePayer: nil,
                            transactions: nil,
                            fees: fees
                        ),
                        error: .getTransferTransactionsFailure
                    )
                }

                // Check fee is greater than sending amount
                var alert: WormholeSendInputAlert?
                if
                    let price = input.solanaAccount.price,
                    let inputAmountInFiat = try? input.amount.toFiatAmount(price: price)
                {
                    if input.amount.amount > 0, inputAmountInFiat <= fees.totalInFiat {
                        alert = .feeIsMoreThanInputAmount
                    }
                }

                return .ready(
                    input: input,
                    output: .init(
                        feePayer: feePayerBestCandidate,
                        transactions: transactions,
                        fees: fees
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
