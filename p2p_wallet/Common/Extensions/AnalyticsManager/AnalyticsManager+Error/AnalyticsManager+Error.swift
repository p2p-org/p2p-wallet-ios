import AnalyticsManager
import Foundation

extension AnalyticsManager {
    /// Handle clientFrontendError & backendError
    func log(error: Error) {
        // Frontend error
        if error.isFrontendError {
//            log(event: .clientFrontendError(
//                errorValue: <#T##String#>,
//                errorFragment: <#T##String#>)
//            )
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
        self is AnalyticsManagerBackendError
    }

    var isFrontendError: Bool {
        !isUserError && !isBackendError
    }
}
