import AnalyticsManager
import FeeRelayerSwift
import Foundation
import NameService
import Onboarding
import SolanaSwift
import Web3

extension AnalyticsManager {
    /// Handle clientFrontendError & backendError
    func log(title: String, error: Error) {
        let event: KeyAppAnalyticsEvent
        // Frontend error
        switch error.errorType {
        case .user:
            return
        case .frontend:
            event = .clientFrontendError(
                errorValue: title,
                errorFragment: (self as? LocalizedError)?.errorDescription ?? String(reflecting: error)
            )
        case .backend:
            event = .clientBackendError(
                errorValue: title,
                errorFragment: (self as? LocalizedError)?.errorDescription ?? String(reflecting: error)
            )
        }

        log(event: event)
    }
}

private enum ErrorType {
    case user
    case frontend
    case backend
}

private extension Error {
    var errorType: ErrorType {
        // user error
        if isNetworkConnectionError {
            return .user
        }

        // backend
        if (self is UndefinedNameServiceError) ||
            (self is NameServiceError) ||
            (self is GetNameError) ||
            (self is SolanaSwift.APIClientError) ||
            (self is DecodingError) ||
            (self is Web3.Eth.Error) ||
            (self is Onboarding.APIGatewayError) ||
            (self is APIGatewayCooldownError) ||
            (self is UndefinedAPIGatewayError) ||
            (self is FeeRelayerSwift.HTTPClientError)
        {
            return .backend
        }

        // frontend
        return .frontend
    }
}
