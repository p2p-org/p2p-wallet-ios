import Foundation
import SolanaSwift

extension RecipientSearchServiceImpl {
    /// Search by solana address
    func searchBySolanaAddress(
        _ address: PublicKey,
        env: UserWalletEnvironments,
        preChosenToken: Token?
    ) async -> RecipientSearchResult {
        do {
            // get address
            let addressBase58 = address.base58EncodedString

            // set attributes
            var attributes: Recipient.Attribute = []

            // Check self-sending
            if let wallet: Wallet = env.wallets
                .first(where: { (wallet: Wallet) in wallet.pubkey == addressBase58 })
            {
                return .selfSendingError(recipient: .init(
                    address: addressBase58,
                    category: wallet.isNativeSOL ? .solanaAddress : .solanaTokenAddress(
                        walletAddress: (try? PublicKey(string: env.wallets.first(where: \.isNativeSOL)?
                                .pubkey)) ?? address,
                        token: wallet.token
                    ),
                    attributes: [.funds, attributes]
                ))
            }

            let account: BufferInfo<SolanaAddressInfo>? = try await solanaClient
                .getAccountInfo(account: addressBase58)

            // detect pda wallet
            if PublicKey.isOnCurve(publicKeyBytes: address.data) == 0 {
                attributes.insert(.pda)
            }

            if let account = account {
                switch account.data {
                case .empty:
                    // Detect wallet address
                    return .ok([
                        .init(
                            address: addressBase58,
                            category: .solanaAddress,
                            attributes: [.funds, attributes]
                        ),
                    ])
                case let .splAccount(accountInfo):
                    // detect token
                    let token = env.tokens
                        .first(where: { $0.address == accountInfo.mint.base58EncodedString }) ??
                        .unsupported(mint: accountInfo.mint.base58EncodedString)

                    // detect category
                    let category = Recipient.Category.solanaTokenAddress(
                        walletAddress: try .init(string: accountInfo.owner.base58EncodedString),
                        token: token
                    )

                    // Detect token account
                    let recipient: Recipient = .init(
                        address: addressBase58,
                        category: category,
                        attributes: [.funds, attributes]
                    )

                    if let wallet = env.wallets
                        .first(where: { $0.token.address == accountInfo.mint.base58EncodedString }),
                        (wallet.lamports ?? 0) > 0,
                        token.address == preChosenToken?.address ?? token.address
                    {
                        // User has the same token
                        return .ok([recipient])
                    } else {
                        // User doesn't have the same token
                        return .missingUserToken(recipient: recipient)
                    }
                }
            } else {
                let splAccounts = try await solanaClient.getTokenAccountsByOwner(
                    pubkey: address.base58EncodedString,
                    params: .init(
                        mint: nil,
                        programId: TokenProgram.id.base58EncodedString
                    ),
                    configs: .init(encoding: "base64")
                )

                if splAccounts.isEmpty {
                    // This account doesn't exits in blockchain
                    return .ok([.init(
                        address: addressBase58,
                        category: .solanaAddress,
                        attributes: [.funds, attributes]
                    )])
                } else {
                    return .ok([.init(
                        address: addressBase58,
                        category: .solanaAddress,
                        attributes: [.funds, attributes]
                    )])
                }
            }
        } catch let error as SolanaSwift.APIClientError {
            return handleSolanaAPIClientError(error)
        } catch {
            print(error)
            return .solanaServiceError(error as NSError)
        }
    }

    // MARK: - Helpers

    func checkBalanceForCreateAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        if wallets.contains(where: { !$0.token.isNativeSOL }) {
            // User has spl account
            if try await checkBalanceForCreateSPLAccount(env: env) {
                return true
            }
        }

        if wallets.contains(where: \.token.isNativeSOL) {
            // User has only SOL
            if try await checkBalanceForCreateNativeAccount(env: env) {
                return true
            }
        }

        return false
    }

    func checkBalanceForCreateNativeAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        for wallet in wallets {
            try Task.checkCancellation()

            guard
                let balance = wallet.lamports,
                let mint = try? PublicKey(string: wallet.token.address)
            else { continue }

            let result = try await swapService.calculateFeeInPayingToken(
                feeInSOL: .init(transaction: 0, accountBalances: env.rentExemptionAmountForWalletAccount),
                payingFeeTokenMint: mint
            )

            let rentExemptionAmountForWalletAccountInToken = result?.accountBalances ?? 0
            if balance > rentExemptionAmountForWalletAccountInToken {
                return true
            }
        }

        return false
    }

    func checkBalanceForCreateSPLAccount(env: UserWalletEnvironments) async throws -> Bool {
        let wallets = env.wallets

        for wallet in wallets {
            try Task.checkCancellation()

            guard
                let balance = wallet.lamports,
                let mint = try? PublicKey(string: wallet.token.address)
            else { continue }

            let result = try await swapService.calculateFeeInPayingToken(
                feeInSOL: .init(transaction: 0, accountBalances: env.rentExemptionAmountForSPLAccount),
                payingFeeTokenMint: mint
            )

            let rentExemptionAmountForWalletAccountInToken = result?.accountBalances ?? 0
            if balance > rentExemptionAmountForWalletAccountInToken {
                return true
            }
        }

        return false
    }

    func handleSolanaAPIClientError(_ error: APIClientError) -> RecipientSearchResult {
        switch error {
        case let .responseError(detailedError):
            if detailedError.code == -32602 { return .ok([]) }
        default:
            break
        }
        debugPrint(error)
        return .solanaServiceError(error as NSError)
    }
}
