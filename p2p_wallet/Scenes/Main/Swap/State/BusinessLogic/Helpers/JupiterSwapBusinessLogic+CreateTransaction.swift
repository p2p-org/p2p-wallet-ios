import Foundation
import SolanaSwift
import Jupiter

extension JupiterSwapBusinessLogic {
    static func createTransaction(
        account: KeyPair?,
        route: Route?,
        jupiterClient: JupiterAPI
    ) async throws -> String {
        do {
            // assert needed infos
            guard let account else {
                throw JupiterSwapError.createTransactionError(.unauthorized)
            }
            
            // assert route
            guard let route else {
                throw JupiterSwapError.createTransactionError(.routeNotFound)
            }

            let swapTransaction = try await jupiterClient.swap(
                route: route,
                userPublicKey: account.publicKey.base58EncodedString,
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
