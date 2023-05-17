import Send
import SolanaSwift
import Resolver
import FeeRelayerSwift

struct SendTransaction: RawTransactionType {
    // MARK: - Properties

    let isFakeSendTransaction: Bool
    let isFakeSendTransactionError: Bool
    let isFakeSendTransactionNetworkError: Bool
    let recipient: Recipient
    let sendViaLinkSeed: String?
    let amount: Double
    let amountInFiat: Double
    let walletToken: Wallet
    let address: String
    let payingFeeWallet: Wallet?
    let feeAmount: FeeAmount
    let currency: String
    
    // MARK: - Computed properties

    var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }
    
    var token: Token {
        walletToken.token
    }
    
    var userDomainName: String? {
        if case let .username(name, domain) = recipient.category {
            return [name, domain].joined(separator: ".")
        }
        return nil
    }

    var mainDescription: String {
        return amount.toString(maximumFractionDigits: 9) + " " + token
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
                throw SolanaError.unknown
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
            let trx = try await Resolver.resolve(SendActionService.self).send(
                from: walletToken,
                receiver: address,
                amount: amount,
                feeWallet: payingFeeWallet,
                ignoreTopUp: isSendingViaLink,
                memo: isSendingViaLink ? .secretConfig("SEND_VIA_LINK_MEMO_PREFIX")! + "-send" : nil,
                operationType: isSendingViaLink ? .sendViaLink : .transfer
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
            let platform = "iOS \(await UIDevice.current.systemVersion)"
            let userPubkey = Resolver.resolve(UserWalletManager.self).wallet?.account.publicKey.base58EncodedString ?? ""
            
            var blockchainError: String?
            var feeRelayerError: String?
            switch error {
            case let error as APIClientError:
                blockchainError = error.content
            default:
                feeRelayerError = "\(error)"
            }
            
            let appVersion = AppInfo.appVersionDetail
            let timestamp = "\(Int64(Date().timeIntervalSince1970 * 1000))"
            
            if isSendingViaLink {
                sendViaLinkAlert(
                    error: error,
                    userPubkey: userPubkey,
                    platform: platform,
                    blockchainError: blockchainError,
                    feeRelayerError: feeRelayerError,
                    appVersion: appVersion,
                    timestamp: timestamp
                )
            } else {
                sendAlert(
                    error: error,
                    userPubkey: userPubkey,
                    platform: platform,
                    blockchainError: blockchainError,
                    feeRelayerError: feeRelayerError,
                    appVersion: appVersion,
                    timestamp: timestamp
                )
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
            data: SendViaLinkAlertLoggerMessage(
                tokenToSend: .init(
                    name: walletToken.name,
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
            .jsonString,
            logLevel: .alert
        )
    }
    
    private func sendAlert(
        error: Swift.Error,
        userPubkey: String,
        platform: String,
        blockchainError: String?,
        feeRelayerError: String?,
        appVersion: String,
        timestamp: String
    ) {
        
        let relayAccountStatus = Resolver.resolve(RelayContextManager.self)
            .currentContext?
            .relayAccountStatus
        
        let relayAccountState: SendAlertLoggerRelayAccountState?
        switch relayAccountStatus {
        case .notYetCreated:
            relayAccountState = .init(
                created: false,
                balance: "0"
            )
        case .created(let lamports):
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
            data: SendAlertLoggerMessage(
                tokenToSend: .init(
                    name: walletToken.name,
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
            .jsonString,
            logLevel: .alert
        )
    }
}

// MARK: - Helpers

private func saveSendViaLinkTransaction(
    seed: String,
    token: Token,
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
