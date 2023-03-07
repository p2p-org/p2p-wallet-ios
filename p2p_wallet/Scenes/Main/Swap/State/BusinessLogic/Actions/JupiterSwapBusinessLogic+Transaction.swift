import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func createTransaction(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        do {
            guard let route = state.route else {
                return state.error(.routeIsNotFound)
            }

            guard let account = state.account else {
                return state.error(.createTransactionFailed)
            }

            let swapTransaction = try await services.jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                asLegacyTransaction: nil,
                computeUnitPriceMicroLamports: nil,
                destinationWallet: nil
            )

            return state.modified {
                $0.status = .ready
                $0.swapTransaction = swapTransaction
            }
        }
        catch let error {
            if (error as NSError).isNetworkConnectionError {
                return state.error(.networkConnectionError)
            }
            return state.error(.createTransactionFailed)
        }
    }
}
