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
        // Frontend error
        if error.isFrontendError {
            log(event: .clientFrontendError(
                errorValue: title,
                errorFragment: (self as? LocalizedError)?.errorDescription ?? String(reflecting: error)
            ))
        }
        // Backend error
        else if error.isBackendError {
            // TODO: - Logging
        }
    }
}

private extension Error {
    var isUserError: Bool {
        isNetworkConnectionError
    }

    var isBackendError: Bool {
        (self is UndefinedNameServiceError) ||
            (self is NameServiceError) ||
            (self is GetNameError) ||
            (self is SolanaSwift.APIClientError) ||
            (self is DecodingError) ||
            (self is Web3.Eth.Error) ||
            (self is Onboarding.APIGatewayError) ||
            (self is APIGatewayCooldownError) ||
            (self is UndefinedAPIGatewayError) ||
            (self is FeeRelayerSwift.HTTPClientError)
    }

    var isFrontendError: Bool {
        !isUserError && !isBackendError
    }
}
