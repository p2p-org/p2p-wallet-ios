import Send
import SolanaSwift
import Resolver

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
    
    // MARK: - Computed properties

    var isSendingViaLink: Bool {
        sendViaLinkSeed != nil
    }
    
    var token: Token {
        walletToken.token
    }

    var mainDescription: String {
        var username: String?
        if case let .username(name, domain) = recipient.category {
            username = [name, domain].joined(separator: ".")
        }
        return amount.toString(maximumFractionDigits: 9) + " " + token
            .symbol + " → " + (username ?? recipient.address.truncatingMiddle(numOfSymbolsRevealed: 4))
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
