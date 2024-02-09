import AnalyticsManager
import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import Resolver
import Send
import SolanaSwift

struct SendTransaction: RawTransactionType {
    // MARK: - Properties

    let isFakeSendTransaction: Bool
    let isFakeSendTransactionError: Bool
    let isFakeSendTransactionNetworkError: Bool
    let isLinkCreationAvailable: Bool
    let recipient: Recipient
    let sendViaLinkSeed: String?
    let amount: Double
    let isSendingMaxAmount: Bool
    let amountInFiat: Double
    let walletToken: SolanaAccount
    let address: String
    let payingFeeWallet: SolanaAccount?
    let feeAmount: FeeAmount
    let currency: String
    let analyticEvent: KeyAppAnalyticsEvent

    // MARK: - Computed properties

    var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }

    var token: TokenMetadata {
        walletToken.token
    }

    var userDomainName: String? {
        if case let .username(name, domain) = recipient.category {
            return [name, domain].joined(separator: ".")
        }
        return nil
    }

    var mainDescription: String {
        amount.toString(maximumFractionDigits: 9) + " " + token
            .symbol + " → " + (userDomainName ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 4))
    }

    // MARK: - Methods

    func createRequest() async throws -> String {
        // save recipient except send via link
        if !isSendingViaLink {
            try? await Resolver.resolve(SendHistoryService.self).insert(recipient)
        }

        // Fake transaction for testing
        #if !RELEASE
            if isFakeSendTransaction {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                if isFakeSendTransactionError {
                    throw FakeTransactionError.random
                }
                if isFakeSendTransactionNetworkError {
                    throw NSError(domain: "Network error", code: NSURLErrorNetworkConnectionLost)
                }
                // save to storage
                if isSendingViaLink, let sendViaLinkSeed {
                    saveSendViaLinkTransaction(
                        seed: sendViaLinkSeed,
                        token: token,
                        amountInToken: amount,
                        amountInFiat: amountInFiat
                    )
                }

                return .fakeTransactionSignature(id: UUID().uuidString)
            }
        #endif

        // Real transaction
        do {
            let trx = try await Resolver.resolve(SendActionService.self)
                .send(
                    from: walletToken,
                    receiver: address,
                    amount: amount,
                    isSendingMaxAmount: isSendingMaxAmount,
                    feeWallet: payingFeeWallet,
                    ignoreTopUp: isSendingViaLink || isLinkCreationAvailable,
                    memo: nil,
                    operationType: isSendingViaLink ? .sendViaLink : .transfer,
                    useSendService: true
                )

            // save to storage
            if isSendingViaLink, let sendViaLinkSeed {
                saveSendViaLinkTransaction(
                    seed: sendViaLinkSeed,
                    token: token,
                    amountInToken: amount,
                    amountInFiat: amountInFiat
                )
            }

            return trx
        } catch {
            // send alert
            let data = await AlertLoggerDataBuilder.buildLoggerData(error: error)

            if isSendingViaLink {
                sendViaLinkAlert(
                    error: error,
                    userPubkey: data.userPubkey,
                    platform: data.platform,
                    blockchainError: data.blockchainError,
                    feeRelayerError: data.feeRelayerError,
                    appVersion: data.appVersion,
                    timestamp: data.timestamp
                )
            } else {
                Task.detached {
                    await sendAlert(
                        error: error,
                        userPubkey: data.userPubkey,
                        platform: data.platform,
                        blockchainError: data.blockchainError,
                        feeRelayerError: data.feeRelayerError,
                        appVersion: data.appVersion,
                        timestamp: data.timestamp
                    )
                }
            }

            // rethrow error
            throw error
        }
    }

    // MARK: - Helpers

    private func sendViaLinkAlert(
        error: Swift.Error,
        userPubkey: String,
        platform: String,
        blockchainError: String?,
        feeRelayerError: String?,
        appVersion: String,
        timestamp: String
    ) {
        DefaultLogManager.shared.log(
            event: "Link Create iOS Alarm",
            logLevel: .alert,
            data: SendViaLinkAlertLoggerMessage(
                tokenToSend: .init(
                    name: walletToken.address,
                    mint: walletToken.mintAddress,
                    sendAmount: amount.toString(maximumFractionDigits: 9),
                    currency: currency
                ),
                userPubkey: userPubkey,
                platform: platform,
                appVersion: appVersion,
                timestamp: timestamp,
                simulationError: nil,
                feeRelayerError: feeRelayerError,
                blockchainError: blockchainError
            )
        )

        Resolver.resolve(AnalyticsManager.self).log(title: "Link Create iOS Error", error: error)
    }

    private func sendAlert(
        error: Swift.Error,
        userPubkey: String,
        platform: String,
        blockchainError: String?,
        feeRelayerError: String?,
        appVersion: String,
        timestamp: String
    ) async {
        let relayAccountStatus = try? await Resolver.resolve(RelayContextManager.self)
            .getCurrentContextOrUpdate()
            .relayAccountStatus

        let relayAccountState: SendAlertLoggerRelayAccountState?
        switch relayAccountStatus {
        case .notYetCreated:
            relayAccountState = .init(
                created: false,
                balance: "0"
            )
        case let .created(lamports):
            relayAccountState = .init(
                created: true,
                balance: lamports.convertToBalance(decimals: 9)
                    .toString(maximumFractionDigits: 9)
            )
        case .none:
            relayAccountState = nil
        }

        DefaultLogManager.shared.log(
            event: "Send iOS Alarm",
            logLevel: .alert,
            data: SendAlertLoggerMessage(
                tokenToSend: .init(
                    name: walletToken.address,
                    mint: walletToken.mintAddress,
                    sendAmount: amount.toString(maximumFractionDigits: 9),
                    currency: currency
                ),
                fees: .init(
                    transactionFeeAmount: feeAmount.transaction
                        .convertToBalance(decimals: payingFeeWallet?.token.decimals ?? 0)
                        .toString(maximumFractionDigits: 9),
                    accountCreationFee: .init(
                        paymentToken: .init(
                            name: payingFeeWallet?.token.name ?? "",
                            mint: payingFeeWallet?.mintAddress ?? ""
                        ),
                        amount: feeAmount.accountBalances
                            .convertToBalance(decimals: payingFeeWallet?.token.decimals ?? 0)
                            .toString(maximumFractionDigits: 9)
                    )
                ),
                relayAccountState: relayAccountState,
                userPubkey: userPubkey,
                recipientPubkey: recipient.address,
                recipientName: userDomainName,
                platform: platform,
                appVersion: appVersion,
                timestamp: timestamp,
                simulationError: nil,
                feeRelayerError: feeRelayerError,
                blockchainError: blockchainError
            )
        )

        Resolver.resolve(AnalyticsManager.self).log(title: "Send iOS Error", error: error)
    }
}

// MARK: - Helpers

private func saveSendViaLinkTransaction(
    seed: String,
    token: TokenMetadata,
    amountInToken: Double,
    amountInFiat: Double
) {
    Task {
        await Resolver.resolve(SendViaLinkStorage.self).save(
            transaction: .init(
                amount: amountInToken,
                amountInFiat: amountInFiat,
                token: token,
                seed: seed,
                timestamp: Date()
            )
        )
    }
}
