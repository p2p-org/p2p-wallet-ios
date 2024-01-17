import FeeRelayerSwift
import Foundation
import KeyAppKitCore
import SolanaSwift

extension SendInputBusinessLogic {
    static func changeFeeToken(
        state: SendInputState,
        feeToken: SolanaAccount,
        services: SendInputServices
    ) async -> SendInputState {
        guard let feeRelayerContext = state.feeRelayerContext else {
            return state.copy(
                status: .error(reason: .missingFeeRelayer),
                tokenFee: feeToken
            )
        }

        do {
            let fee: FeeAmount
            let feeInToken: FeeAmount
            if state.isSendingViaLink {
                fee = .zero
                feeInToken = .zero
            } else {
                fee = try await services.feeService.getFees(
                    from: state.token,
                    recipient: state.recipient,
                    recipientAdditionalInfo: state.recipientAdditionalInfo,
                    payingTokenMint: feeToken.mintAddress,
                    feeRelayerContext: feeRelayerContext
                ) ?? .zero
                feeInToken = try (try? await services.swapService.calculateFeeInPayingToken(
                    feeInSOL: fee,
                    payingFeeTokenMint: PublicKey(string: feeToken.mintAddress)
                )) ?? .zero
            }

            let state = state.copy(
                fee: fee,
                tokenFee: feeToken,
                feeInToken: feeInToken
            )

            return await validateFee(state: state)
        } catch {
            return await handleFeeCalculationError(state: state, services: services, error: error)
        }
    }
}
