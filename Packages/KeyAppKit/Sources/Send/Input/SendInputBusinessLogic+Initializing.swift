import FeeRelayerSwift
import Foundation
import KeyAppNetworking
import SolanaSwift

extension SendInputBusinessLogic {
    static func initialize(
        state: SendInputState,
        services: SendInputServices
    ) async -> SendInputState {
        do {
            guard let userWalletAddress = state.userWalletEnvironments.userWalletAddress else {
                throw SendError.invalidUserAccount
            }
            var recipientAdditionalInfo = SendInputState.RecipientAdditionalInfo.zero

            async let lamportsPerSignature = services.solanaAPIClient.getLamportsPerSignature()
            async let minimumRelayAccountBalance = services.solanaAPIClient.getMinimumBalanceForRentExemption(span: 0)
            async let limit = services.rpcService.getLimit(
                userWallet: userWalletAddress
            )
            async let feePayableTokenMints = services.rpcService.getCompensationTokens()

            switch state.recipient.category {
            case .solanaAddress, .username:
                async let walletAccount: BufferInfo<SolanaAddressInfo>? = services.solanaAPIClient
                    .getAccountInfo(account: state.recipient.address)

                async let tokenAccounts = services.solanaAPIClient
                    .getTokenAccountsByOwnerWithToken2022(
                        pubkey: state.recipient.address,
                        configs: .init(encoding: "base64")
                    )

                // Analyse destination spl addresses
                recipientAdditionalInfo = try await .init(
                    walletAccount: walletAccount,
                    splAccounts: tokenAccounts
                )
            case let .solanaTokenAddress(walletAddress, _):
                async let walletAccount: BufferInfo<SolanaAddressInfo>? = services.solanaAPIClient
                    .getAccountInfo(account: walletAddress.base58EncodedString)
                async let tokenAccounts = services.solanaAPIClient
                    .getTokenAccountsByOwnerWithToken2022(
                        pubkey: walletAddress.base58EncodedString,
                        configs: .init(encoding: "base64")
                    )

                recipientAdditionalInfo = try await .init(
                    walletAccount: walletAccount,
                    splAccounts: tokenAccounts
                )
            default:
                break
            }

            let state = try await state.copy(
                status: .ready,
                recipientAdditionalInfo: recipientAdditionalInfo,
                feePayableTokenMints: feePayableTokenMints,
                lamportsPerSignature: lamportsPerSignature,
                minimumRelayAccountBalance: minimumRelayAccountBalance,
                limit: limit
            )

            return await changeToken(
                state: state,
                token: state.token,
                services: services
            )
        } catch {
            return state.copy(
                status: .error(
                    reason: .initializeFailed(error as NSError)
                )
            )
        }
    }
}
