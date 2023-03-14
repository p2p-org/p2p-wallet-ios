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
    
    /// Unknown
    case unknown
}

/// Description for route calculation error
enum JupiterSwapRouteCalculationErrorDescription: String, Equatable {
    case amountFromIsZero
    case swapToSameToken
    case amountToIsZero
    case routeNotFound
    case networkError
    case unknown
}

/// Description for validation error
enum JupiterSwapAmountValidationErrorDescription: Equatable {
    case notEnoughFromToken
    case amountFromIsZero
    case inputTooHigh(Double) // FIXME: - Naming?
    case networkError
    case unknown
}

/// Description for creating transaction error
enum JupiterSwapCreateTransactionErrorDescription: String, Equatable {
    case unauthorized
    case routeNotFound
    case transactionIsNil
    case networkError
    case unknown
}
