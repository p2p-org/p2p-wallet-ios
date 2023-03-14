import Foundation

/// Error in JupiterSwap
enum JupiterSwapError: Error, Equatable {
    /// Error in initializing data
    case initializingError
    
    /// Error in calculating route
    case routeCalculationError(JupiterSwapRouteCalculationErrorDescription)
    
    /// Error in validating data
    case validationError(JupiterSwapAmountValidationErrorDescription)
    
    /// Error in creating transaction
    case createTransactionError(JupiterSwapCreateTransactionErrorDescription)
    
    /// Network error
    case networkError
    
    /// Unknown error
    case unknown
}

/// Description for route calculation error
enum JupiterSwapRouteCalculationErrorDescription: String, Equatable {
    case routeNotFound
}

/// Description for validation error
enum JupiterSwapAmountValidationErrorDescription: Equatable {
    case unauthorized
    case notEnoughFromToken
    case amountFromIsZero
    case swapToSameToken
    case amountToIsZero
    case inputTooHigh(Double) // FIXME: - Naming?
}

/// Description for creating transaction error
enum JupiterSwapCreateTransactionErrorDescription: String, Equatable {
    case transactionIsNil
    case networkError
    case unknown
}
