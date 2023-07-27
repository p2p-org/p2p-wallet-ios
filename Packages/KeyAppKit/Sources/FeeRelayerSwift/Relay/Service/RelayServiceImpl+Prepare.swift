//
//  File.swift
//
//
//  Created by Giang Long Tran on 02.04.2023.
//

import Foundation
import SolanaSwift

extension RelayServiceImpl {
    func prepareRelayTransaction(
        preparedTransaction: PreparedTransaction,
        payingFeeToken: TokenAccount?,
        relayAccountStatus: RelayAccountStatus,
        additionalPaybackFee: UInt64,
        operationType _: StatsInfo.OperationType,
        currency _: String?,
        autoPayback: Bool
    ) async throws -> PreparedTransaction {
        // get current context
        guard let context = contextManager.currentContext else {
            throw RelayContextManagerError.invalidContext
        }
        let feePayer = context.feePayerAddress

        // verify fee payer
        guard feePayer == preparedTransaction.transaction.feePayer else {
            throw FeeRelayerError.invalidFeePayer
        }

        // Calculate the fee to send back to feePayer
        // Account creation fee (accountBalances) is a must-pay-back fee
        var paybackFee = additionalPaybackFee + preparedTransaction.expectedFee.accountBalances

        // The transaction fee, on the other hand, is only be paid if user used more than number of free transaction fee
        if !context.usageStatus
            .isFreeTransactionFeeAvailable(transactionFee: preparedTransaction.expectedFee.transaction)
        {
            paybackFee += preparedTransaction.expectedFee.transaction
        }

        // transfer sol back to feerelayer's feePayer
        var preparedTransaction = preparedTransaction
        if autoPayback, paybackFee > 0 {
            // if payingFeeToken is native sol, use SystemProgram
            if payingFeeToken?.mint == PublicKey.wrappedSOLMint,
               (relayAccountStatus.balance ?? 0) < paybackFee
            {
                preparedTransaction.transaction.instructions.append(
                    SystemProgram.transferInstruction(
                        from: account.publicKey,
                        to: feePayer,
                        lamports: paybackFee
                    )
                )
            }

            // if payingFeeToken is SPL token, use RelayProgram
            else {
                // return paybackFee (WITHOUT additionalPaybackFee) to Fee payer
                preparedTransaction.transaction.instructions.append(
                    try RelayProgram.transferSolInstruction(
                        userAuthorityAddress: account.publicKey,
                        recipient: feePayer,
                        lamports: paybackFee - additionalPaybackFee, // Important: MINUS additionalPaybackFee
                        network: solanaApiClient.endpoint.network
                    )
                )

                // Return additional payback fee from USER ACCOUNT to FeePayer using SystemProgram
                if additionalPaybackFee > 0 {
                    preparedTransaction.transaction.instructions.append(
                        SystemProgram.transferInstruction(
                            from: account.publicKey,
                            to: feePayer,
                            lamports: paybackFee
                        )
                    )
                }
            }
        }

        #if DEBUG
//        if let decodedTransaction = preparedTransaction.transaction.jsonString {
//            Logger.log(message: decodedTransaction, event: .info)
//        }
            print(preparedTransaction.transaction.jsonString!)
        #endif

        // resign transaction if needed
        if !preparedTransaction.signers.isEmpty {
            try preparedTransaction.transaction.sign(signers: preparedTransaction.signers)
        }

        // return prepared transaction
        return preparedTransaction
    }
}
