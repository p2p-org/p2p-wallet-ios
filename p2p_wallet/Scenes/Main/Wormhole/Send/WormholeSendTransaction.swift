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
