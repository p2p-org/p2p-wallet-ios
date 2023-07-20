import Foundation

public enum StrigaProviderError: Error {
    case invalidRequest(String)
    case invalidResponse
    case invalidRateTokens

    case missingAccountId
}
