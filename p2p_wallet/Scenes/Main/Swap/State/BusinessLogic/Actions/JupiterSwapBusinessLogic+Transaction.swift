import Jupiter
import SolanaSwift

extension JupiterSwapBusinessLogic {
    static func createTransaction(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async -> JupiterSwapState {
        do {
            let state = state.modified {
                $0.swapTransaction = nil
            }
            
            guard state.isTransactionCanBeCreated else {
                return state
            }
            
            guard let route = state.route else {
//                return state.error(.routeIsNotFound)
                return state
            }

            guard let account = state.account else {
//                return state.error(.createTransactionFailed)
                return state
            }

            let swapTransaction = try await services.jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
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
