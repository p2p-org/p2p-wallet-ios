import Foundation
import SolanaSwift

enum JupiterSwapAmountValidationError: JupiterSwapError {
    case notEnoughFromToken
    case amountFromIsZero
    case inputTooHigh(Double) // FIXME: - Naming?
}

extension JupiterSwapBusinessLogic {
    static func validateAmounts(
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async throws {
        // get status
        let status: JupiterSwapState.Status
        
        // assert balance is not nil
        guard let balance = state.fromToken.userWallet?.amount
        else {
            throw JupiterSwapAmountValidationError.notEnoughFromToken
        }
        
        // if amount from is greater than current balance
        if state.amountFrom > balance {
            throw JupiterSwapAmountValidationError.notEnoughFromToken
        }
        
        // if amount from is SOL, validate its balance
        else if state.fromToken.address == Token.nativeSolana.address {
            try await validateNativeSOL(balance: balance, state: state, services: services)
        }
        
        // all goods!
        return
    }
    
    // MARK: - Helpers

    private static func validateNativeSOL(
        balance: Double,
        state: JupiterSwapState,
        services: JupiterSwapServices
    ) async throws {
        // assert amount from
        guard let amountFrom = state.amountFrom else {
            throw JupiterSwapAmountValidationError.amountFromIsZero
        }
        do {
            // assert min SOL account balance
            let decimals = state.fromToken.token.decimals
            let minBalance = try await services.relayContextManager
                .getCurrentContextOrUpdate()
                .minimumRelayAccountBalance
            
            // remainder
            let remains = (balance - amountFrom).toLamport(decimals: decimals)
            if remains > 0 && remains < minBalance {
                let maximumInput = (balance.toLamport(decimals: decimals) - minBalance).convertToBalance(decimals: decimals)
                throw JupiterSwapAmountValidationError.inputTooHigh(maximumInput)
            } else {
                return
            }
        } catch {
            if (error as NSError).isNetworkConnectionError {
                throw JupiterSwapGeneralError.networkError
            }
            throw JupiterSwapGeneralError.unknown
        }
    }
}
