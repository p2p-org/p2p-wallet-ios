import AnalyticsManager
import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift

struct ClaimSentViaLinkTransaction: RawTransactionType {
    // MARK: - Properties

    let claimableTokenInfo: ClaimableTokenInfo
    let token: TokenMetadata
    let destinationWallet: SolanaAccount
    let tokenAmount: Double

    let payingFeeWallet: SolanaAccount? = nil
    let feeAmount: FeeAmount = .zero
    let isFakeTransaction: Bool
    let fakeTransactionErrorType: FakeTransactionErrorType

    var mainDescription: String {
        "Claim-sent-via-link"
    }

    var amountInFiat: Double? {
        guard let value = destinationWallet.price?.doubleValue else { return nil }
        return value * tokenAmount
    }

    func createRequest() async throws -> String {
        // fake transaction for debugging
        if isFakeTransaction {
            // fake delay api call 1s
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // simulate error if needed
            switch fakeTransactionErrorType {
            case .noError:
                break
            case .otherError:
                throw FakeTransactionError.random
            case .networkError:
                throw NSError(domain: "Network error", code: NSURLErrorNetworkConnectionLost)
            }

            return .fakeTransactionSignature(id: UUID().uuidString)
        }

        // get receiver
        guard let receiver = Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey
        else {
            throw SendActionError.unauthorized
        }

        // get services
        let sendViaLinkDataService = Resolver.resolve(SendViaLinkDataService.self)
        let feeRelayerAPIClient = Resolver.resolve(FeeRelayerAPIClient.self)
        let solanaAPIClient = Resolver.resolve(SolanaAPIClient.self)

        // do and catch error
        do {
            let feePayerAddress = try PublicKey(
                string: await feeRelayerAPIClient.getFeePayerPubkey()
            )

            // prepare transaction, get recent blockchash
            var (preparedTransaction, recentBlockhash) = try await(
                sendViaLinkDataService.claim(
                    token: claimableTokenInfo,
                    receiver: receiver,
                    feePayer: feePayerAddress
                ),
                solanaAPIClient.getRecentBlockhash()
            )

            preparedTransaction.transaction.recentBlockhash = recentBlockhash

            // get feePayer's signature
            let feePayerSignature = try await Resolver.resolve(RelayService.self)
                .signRelayTransaction(
                    preparedTransaction,
                    config: FeeRelayerConfiguration(
                        operationType: .sendViaLink, // TODO: - Received via link?
                        currency: claimableTokenInfo.mintAddress,
                        autoPayback: false
                    )
                )

            // sign transaction by user
            try preparedTransaction.transaction.sign(signers: [claimableTokenInfo.keypair])

            // add feePayer's signature
            try preparedTransaction.transaction.addSignature(
                .init(
                    signature: Data(Base58.decode(feePayerSignature)),
                    publicKey: feePayerAddress
                )
            )

            // serialize transaction
            let serializedTransaction = try preparedTransaction.transaction.serialize().base64EncodedString()

            // send to solanaBlockchain
            return try await solanaAPIClient.sendTransaction(
                transaction: serializedTransaction,
                configs: RequestConfiguration(
                    encoding: "base64",
                    preflightCommitment: "confirmed"
                )!
            )
        } catch {
            // Prepare params
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)

            // alert
            DefaultLogManager.shared.log(
                event: "Link Claim iOS Alarm",
                logLevel: .alert,
                data: ClaimSentViaLinkAlertLoggerMessage(
                    tokenToClaim: .init(
                        name: token.name,
                        mint: token.mintAddress,
                        claimAmount: tokenAmount.toString(maximumFractionDigits: 9),
                        currency: token.symbol
                    ),
                    userPubkey: data.userPubkey,
                    platform: data.platform,
                    appVersion: data.appVersion,
                    timestamp: data.timestamp,
                    simulationError: nil,
                    feeRelayerError: data.feeRelayerError,
                    blockchainError: data.blockchainError
                )
            )

            Resolver.resolve(AnalyticsManager.self).log(title: "Link Claim iOS Error", error: error)

            // rethrow error
            throw error
        }
    }
}
