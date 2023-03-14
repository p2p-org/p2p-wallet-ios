import Foundation

protocol JupiterSwapError: Error {}

enum JupiterSwapGeneralError: JupiterSwapError {
    case networkError
    case unknown
}
