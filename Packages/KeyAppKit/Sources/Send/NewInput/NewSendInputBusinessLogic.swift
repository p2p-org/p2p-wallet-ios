//
//  File.swift
//
//
//  Created by Giang Long Tran on 07.08.2023.
//

import Foundation

enum NSendInputBusinessLogic {
    static func calculate(provider: SendProvider, input: NSendInput) async -> NSendInputState {
        do {
            let result = try await provider.send(
                userWallet: input.userWallet,
                mint: input.token.mintAddress,
                amount: input.amount,
                recipient: input.recipient,
                options: input.configuration
            )

            return .ready(
                input: input,
                output: NSendOutput(
                    transactionDetails: result.transactionDetails,
                    transferAmounts: result.transferAmounts,
                    fees: result.fees
                )
            )
        } catch {
            return .error(input: input, output: nil, error: .unknown(error.localizedDescription))
        }
    }
}
