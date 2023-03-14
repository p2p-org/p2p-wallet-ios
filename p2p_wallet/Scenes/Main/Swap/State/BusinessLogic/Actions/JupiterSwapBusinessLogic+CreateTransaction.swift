import Foundation
import SolanaSwift
import Jupiter

extension JupiterSwapBusinessLogic {
    static func createTransaction(
        account: KeyPair?,
        route: Route?,
        jupiterClient: JupiterAPI
    ) async throws -> JupiterSwapState {
        do {
            // assert needed infos
            guard let account else {
                throw JupiterSwapCreateTransactionError.unauthorized
            }
            
            // assert route
            guard let route = state.route else {
                throw JupiterSwapGeneralError.routeNotFound
            }

            let swapTransaction = try await jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
            )
            
            guard let swapTransaction else {
                throw JupiterSwapCreateTransactionError.creationFailed
            }

            return state.modified {
                $0.status = .ready
                $0.swapTransaction = swapTransaction
            }
        }
        // catch network error and map it to JupiterSwapRouteCalculationError to make sure that only 1 type of error returned
        catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapGeneralError.networkError
            }
            throw JupiterSwapGeneralError.unknown
        }
    }
}
