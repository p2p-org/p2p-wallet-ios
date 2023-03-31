//
//  WormholeSendTransaction.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import FeeRelayerSwift
import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift
import Wormhole

struct WormholeSendTransaction: RawTransactionType {
    let account: SolanaAccountsService.Account

    let recipient: Recipient

    let amount: CryptoAmount

    var currencyAmount: CurrencyAmount {
        guard let price = account.price else { return .zero }
        return amount.unsafeToFiatAmount(price: price)
    }

    let fees: SendFees

    let transaction: Wormhole.SendTransaction

    var mainDescription: String = "Wormhole send"

    var payingFeeWallet: Wallet?

    var feeAmount: FeeAmount = .zero

    func createRequest() async throws -> String {
        let solanaClient: SolanaAPIClient = Resolver.resolve()
        let solanaHelper: SolanaBlockchainClient = Resolver.resolve()
        let userWalletManager: UserWalletManager = Resolver.resolve()
        let sendHistory: SendHistoryService = Resolver.resolve()

        try? await sendHistory.insert(recipient)

        do {
            guard
                let keypair = userWalletManager.wallet?.account,
                let data = Data(base64Encoded: transaction.transaction, options: .ignoreUnknownCharacters),
                var versionedTransaction = try? VersionedTransaction.deserialize(data: data),
                let configs = RequestConfiguration(encoding: "base64")
            else {
                throw Error.decodeTransactionError
            }

            let feeInSolanaNetwork: CryptoAmount = [fees.networkFee, fees.messageAccountRent, fees.bridgeFee]
                .compactMap { $0 }
                .map { tokenAmount in
                    CryptoAmount(bigUIntString: tokenAmount.amount, token: SolanaToken.nativeSolana)
                }
                .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

            let userRelayAccount = try RelayProgram.getUserRelayAddress(
                user: keypair.publicKey,
                network: .mainnetBeta
            )

            let topUpTrx = Transaction(
                instructions: [
                    SystemProgram.transferInstruction(
                        from: keypair.publicKey,
                        to: userRelayAccount,
                        lamports: try UInt64(feeInSolanaNetwork.value) + 10000
                    ),
                ],
                feePayer: keypair.publicKey
            )

            let topUpID = try await solanaHelper
                .sendTransaction(
                    preparedTransaction: .init(
                        transaction: topUpTrx, signers: [keypair],
                        expectedFee: .zero
                    )
                )

            try await solanaHelper.apiClient.waitForConfirmation(signature: topUpID, ignoreStatus: false)

            try versionedTransaction.sign(signers: [keypair])
            let encodedTrx = try versionedTransaction.serialize().base64EncodedString()

            return try await solanaClient.sendTransaction(transaction: encodedTrx, configs: configs)
        } catch {
            print(error)
            throw error
        }
    }

    enum Error: String, Swift.Error {
        case decodeTransactionError
    }
}
