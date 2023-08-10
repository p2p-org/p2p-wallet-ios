//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation
import KeyAppKitCore

enum NSendInputBusinessLogic {
    static func calculate(provider: SendProvider, input: NSendInput) async -> NSendInputState {
        do {
            if input.amount == 0 {
                return .error(input: input, output: nil, error: .noAmount)
            }

            let result = try await provider.send(
                userWallet: input.owner,
                mint: input.account.token.mintAddress,
                amount: input.amount,
                recipient: input.recipient,
                options: input.configuration
            )

            return .ready(
                input: input,
                output: NSendOutput(
                    transactionDetails: TransactionDetails(
                        transaction: result.transaction,
                        blockhash: result.blockhash,
                        expiresAt: result.expiresAt,
                        signature: result.signature
                    ),
                    transferAmounts: TransferAmounts(
                        recipientGetsAmount: result.recipientGetsAmount,
                        totalAmount: result.totalAmount
                    ),
                    fees: TransferFees(
                        networkFee: result.networkFee,
                        tokenAccountRent: result.tokenAccountRent
                    )
                )
            )
        } catch let error as JSONRPCError<String> {
            switch error.code {
            case -32002:
                return .error(input: input, output: nil, error: .insufficientAmount)
            default:
                return .error(input: input, output: nil, error: .server(code: error.code, message: error.message))
            }
        } catch {
            return .error(input: input, output: nil, error: .unknown(error.localizedDescription))
        }
    }
}
