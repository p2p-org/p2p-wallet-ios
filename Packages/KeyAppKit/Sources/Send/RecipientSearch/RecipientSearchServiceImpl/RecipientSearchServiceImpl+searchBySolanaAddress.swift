import Foundation
import KeyAppKitCore
import SolanaSwift

extension RecipientSearchServiceImpl {
    /// Search by solana address
    func searchBySolanaAddress(
        _ address: PublicKey,
        config: RecipientSearchConfig,
        preChosenToken: SolanaToken?
    ) async -> RecipientSearchResult {
        do {
            // get address
            let addressBase58 = address.base58EncodedString

            // set attributes
            var attributes: Recipient.Attribute = []

            // Check self-sending
            if let wallet: SolanaAccount = config.wallets
                .first(where: { (wallet: SolanaAccount) in wallet.address == addressBase58 })
            {
                return .selfSendingError(recipient: .init(
                    address: addressBase58,
                    category: wallet.token.isNative ? .solanaAddress : .solanaTokenAddress(
                        walletAddress: (try? PublicKey(string: config.wallets.first(where: \.token.isNative)?
                                .address)) ?? address,
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
                    let token = config
                        .tokens[accountInfo.mint.base58EncodedString] ??
                        .unsupported(
                            tags: nil,
                            mint: accountInfo.mint.base58EncodedString,
                            decimals: 1,
                            symbol: "",
                            supply: nil
                        )

                    // detect category
                    let category = try Recipient.Category.solanaTokenAddress(
                        walletAddress: .init(string: accountInfo.owner.base58EncodedString),
                        token: token
                    )

                    // Detect token account
                    let recipient: Recipient = .init(
                        address: addressBase58,
                        category: category,
                        attributes: [.funds, attributes]
                    )

                    if let wallet = config.wallets
                        .first(where: { $0.token.mintAddress == accountInfo.mint.base58EncodedString }),
                        wallet.lamports > 0,
                        token.mintAddress == preChosenToken?.mintAddress ?? token.mintAddress
                    {
                        // User has the same token
                        return .ok([recipient])
                    } else {
                        // User doesn't have the same token
                        return .missingUserToken(recipient: recipient)
                    }
                }
            } else {
//                let splAccounts = try await solanaClient.getTokenAccountsByOwner(
//                    pubkey: address.base58EncodedString,
//                    params: .init(
//                        mint: nil,
//                        programId: TokenProgram.id.base58EncodedString
//                    ),
//                    configs: .init(encoding: "base64")
//                )
//
//                if splAccounts.isEmpty {
//                    // This account doesn't exits in blockchain
//                    return .ok([.init(
//                        address: addressBase58,
//                        category: .solanaAddress,
//                        attributes: [.funds, attributes]
//                    )])
//                } else {
                return .ok([.init(
                    address: addressBase58,
                    category: .solanaAddress,
                    attributes: [.funds, attributes]
                )])
//                }
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

        if wallets.contains(where: { !$0.token.isNative }) {
            // User has spl account
            if try await checkBalanceForCreateSPLAccount(env: env) {
                return true
            }
        }

        if wallets.contains(where: \.token.isNative) {
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

            let balance = wallet.lamports
            guard
                let mint = try? PublicKey(string: wallet.token.mintAddress)
            else { continue }

            let result = try await feeCalculator.calculateFeeInPayingToken(
                feeInSOL: .init(
                    transaction: 0,
                    accountBalances: wallet.minRentExemption ?? 2_039_280
                ),
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

            let balance = wallet.lamports
            guard
                let mint = try? PublicKey(string: wallet.token.mintAddress)
            else { continue }

            let result = try await feeCalculator.calculateFeeInPayingToken(
                feeInSOL: .init(
                    transaction: 0,
                    accountBalances: wallet.minRentExemption ?? 2_039_280
                ),
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
