import Foundation
import SolanaSwift
import Jupiter

extension JupiterSwapBusinessLogic {
    static func createTransaction(
        userPublicKey: PublicKey,
        route: Route,
        jupiterClient: JupiterAPI
    ) async throws -> String {
        do {
            let swapTransaction = try await jupiterClient.swap(
                route: route,
                userPublicKey: userPublicKey.base58EncodedString,
                wrapUnwrapSol: true,
                feeAccount: nil,
                computeUnitPriceMicroLamports: nil
            )
            
            guard let swapTransaction else {
                throw JupiterSwapError.createTransactionError(.transactionIsNil)
            }
            
            return swapTransaction
        }
        // catch network error and map it to JupiterSwapRouteCalculationError to make sure that only 1 type of error returned
        catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapError.createTransactionError(.networkError)
            }
            throw JupiterSwapError.createTransactionError(.unknown)
        }
    }
}
