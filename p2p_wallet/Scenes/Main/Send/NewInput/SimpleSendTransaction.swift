import Foundation
import KeyAppBusiness
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift

/// Temporary class!!!
struct SimpleSendTransaction: RawTransactionType {
    let input: NSendInput
    let output: NSendOutput

    var mainDescription: String { "Send" }

    var payingFeeWallet: SolanaAccount? {
        input.account
    }

    var feeAmount: FeeAmount {
        FeeAmount(
            transaction: (try? UInt64(output.fees.networkFee.amount.asCryptoAmount.value)) ?? 0,
            accountBalances: (try? UInt64(output.fees.tokenAccountRent?.amount.asCryptoAmount.value ?? 0)) ?? 0,
            deposit: 0,
            others: nil
        )
    }

    @Injected var accountStorage: SolanaAccountStorage
    @Injected var client: SolanaAPIClient

    func createRequest() async throws -> String {
        guard let account = accountStorage.account else {
            throw Error.unAuth
        }

        guard let base64Data = Data(
            base64Encoded: output.transactionDetails.transaction,
            options: .ignoreUnknownCharacters
        ),
            var versionedTransaction = try? VersionedTransaction.deserialize(data: base64Data)
        else {
            throw Error.parsingError
        }

        try versionedTransaction.sign(signers: [account])

        let transaction = try versionedTransaction.serialize()

        print(">Transaction: ", transaction.base64EncodedString())

        return try await client.sendTransaction(
            transaction: transaction.base64EncodedString(),
            configs: .init(commitment: "confirmed", encoding: "base64")!
        )
    }
}

extension SimpleSendTransaction {
    enum Error: Swift.Error {
        case unAuth
        case parsingError
    }
}
