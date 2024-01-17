import FeeRelayerSwift
import Foundation
import SolanaSwift

extension SendInputBusinessLogic {
    static func initialize(
        state: SendInputState,
        services: SendInputServices,
        params: SendInputActionInitializeParams
    ) async -> SendInputState {
        do {
            var recipientAdditionalInfo = SendInputState.RecipientAdditionalInfo.zero

            switch state.recipient.category {
            case .solanaAddress, .username:
                // Analyse destination spl addresses
                recipientAdditionalInfo = try await .init(
                    walletAccount: services.solanaAPIClient.getAccountInfo(account: state.recipient.address),
                    splAccounts: services.solanaAPIClient
                        .getTokenAccountsByOwnerWithToken2022(
                            pubkey: state.recipient.address,
                            configs: .init(encoding: "base64")
                        )
                )
            case let .solanaTokenAddress(walletAddress, _):
                recipientAdditionalInfo = try await .init(
                    walletAccount: services.solanaAPIClient.getAccountInfo(account: walletAddress.base58EncodedString),
                    splAccounts: services.solanaAPIClient
                        .getTokenAccountsByOwnerWithToken2022(
                            pubkey: walletAddress.base58EncodedString,
                            configs: .init(encoding: "base64")
                        )
                )
            default:
                break
            }

            let state = try state.copy(
                status: .ready,
                recipientAdditionalInfo: recipientAdditionalInfo,
                feeRelayerContext: await params.feeRelayerContext()
            )

            return await changeToken(state: state, token: state.token, services: services)
        } catch {
            return state.copy(status: .error(reason: .initializeFailed(error as NSError)))
        }
    }
}
