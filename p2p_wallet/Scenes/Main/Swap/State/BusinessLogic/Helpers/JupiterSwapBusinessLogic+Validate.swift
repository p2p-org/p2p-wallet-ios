import Foundation
import SolanaSwift
import FeeRelayerSwift

extension JupiterSwapBusinessLogic {
    static func validateAmounts(
        fromToken: SwapToken,
        amountFrom: Double?,
        relayContextManager: RelayContextManager
    ) async throws {
        // get status
        let status: JupiterSwapState.Status
        
        // assert balance is not nil
        guard let balance = fromToken.userWallet?.amount
        else {
            throw JupiterSwapError.validationError(.notEnoughFromToken)
        }
        
        // if amount from is greater than current balance
        if amountFrom > balance {
            throw JupiterSwapError.validationError(.notEnoughFromToken)
        }
        
        // if amount from is SOL, validate its balance
        else if fromToken.address == Token.nativeSolana.address {
            try await validateNativeSOL(
                balance: balance,
                amountFrom: amountFrom,
                fromToken: fromToken.token,
                relayContextManager: relayContextManager
            )
        }
        
        // all goods!
        return
    }
    
    // MARK: - Helpers

    private static func validateNativeSOL(
        balance: Double,
        amountFrom: Double?,
        fromToken: Token,
        relayContextManager: RelayContextManager
    ) async throws {
        // assert amount from
        guard let amountFrom else {
            throw JupiterSwapError.validationError(.amountFromIsZero)
        }
        do {
            // assert min SOL account balance
            let decimals = fromToken.decimals
            let minBalance = try await relayContextManager
                .getCurrentContextOrUpdate()
                .minimumRelayAccountBalance
            
            // remainder
            let remains = (balance - amountFrom).toLamport(decimals: decimals)
            if remains > 0 && remains < minBalance {
                let maximumInput = (balance.toLamport(decimals: decimals) - minBalance).convertToBalance(decimals: decimals)
                throw JupiterSwapError.validationError(.inputTooHigh(maximumInput))
            } else {
                return
            }
        } catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapError.validationError(.networkError)
            }
            throw JupiterSwapError.validationError(.unknown)
        }
    }
}
