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
        let relayService: RelayService = Resolver.resolve()
        let contextManager: RelayContextManager = Resolver.resolve()

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

            let transactionFee: CryptoAmount = [fees.networkFee, fees.bridgeFee]
                .compactMap { $0 }
                .map(\.asCryptoAmount)
                .reduce(CryptoAmount(token: SolanaToken.nativeSolana), +)

            let accountCreationFee = fees.messageAccountRent?
                .asCryptoAmount ?? CryptoAmount(token: SolanaToken.nativeSolana)

            let topUpResult = try await relayService.topUp(
                amount: .init(
                    transaction: UInt64(transactionFee.value),
                    accountBalances: UInt64(accountCreationFee.value)
                ),
                payingFeeToken: .init(
                    address: try PublicKey(string: payingFeeWallet?.pubkey),
                    mint: PublicKey(string: payingFeeWallet?.token.address)
                ),
                relayContext: contextManager.getCurrentContextOrUpdate()
            )

            if let topUpResult {
                for topUp in topUpResult {
                    try await solanaClient.waitForConfirmation(signature: topUp, ignoreStatus: false)
                }
            }

            try versionedTransaction.sign(signers: [keypair])

            let fullySignedTransaction = try await relayService.signTransaction(
                transactions: [versionedTransaction],
                config: .init(operationType: .other)
            ).first

            guard let fullySignedTransaction else {
                throw Error.relaySigningFailure
            }

            let encodedTrx = try fullySignedTransaction.serialize().base64EncodedString()

            return try await solanaClient.sendTransaction(transaction: encodedTrx, configs: configs)
        } catch {
            print(error)
            throw error
        }
    }

    enum Error: String, Swift.Error {
        case decodeTransactionError
        case relaySigningFailure
    }
}
