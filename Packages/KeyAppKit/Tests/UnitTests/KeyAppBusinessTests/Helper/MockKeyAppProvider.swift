import Foundation
@testable import KeyAppBusiness

class MockKeyAppTokenProvider: KeyAppTokenProvider {
    var tokensInfoResult: [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Token>]?
    var tokensPriceResult: [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Price>]?
    var solanaTokensResult: KeyAppTokenProviderData.AllSolanaTokensResult?

    func getTokensInfo(_: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
    -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Token>] {
        guard let result = tokensInfoResult else {
            throw MockKeyAppTokenProviderError.missingResult
        }
        return result
    }

    func getTokensPrice(_: KeyAppTokenProviderData.Params<KeyAppTokenProviderData.TokenQuery>) async throws
    -> [KeyAppTokenProviderData.TokenResult<KeyAppTokenProviderData.Price>] {
        guard let result = tokensPriceResult else {
            throw MockKeyAppTokenProviderError.missingResult
        }
        return result
    }

    func getSolanaTokens(modifiedSince _: Date?) async throws -> KeyAppTokenProviderData.AllSolanaTokensResult {
        guard let result = solanaTokensResult else {
            throw MockKeyAppTokenProviderError.missingResult
        }
        return result
    }
}

enum MockKeyAppTokenProviderError: Error {
    case missingResult
}
