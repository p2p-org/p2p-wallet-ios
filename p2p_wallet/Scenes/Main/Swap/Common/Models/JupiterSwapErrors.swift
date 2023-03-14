import Foundation

protocol JupiterSwapError: Error, Equatable {}

enum JupiterSwapGeneralError: JupiterSwapError {
    case routeNotFound
    case networkError
    case unknown
}

enum JupiterSwapRouteCalculationError: JupiterSwapError {
    case amountFromIsZero
    case swapToSameToken
    case amountToIsZero
}

enum JupiterSwapAmountValidationError: JupiterSwapError {
    case notEnoughFromToken
    case amountFromIsZero
    case inputTooHigh(Double) // FIXME: - Naming?
}

enum JupiterSwapCreateTransactionError: JupiterSwapError {
    case unauthorized
    case creationFailed
}
