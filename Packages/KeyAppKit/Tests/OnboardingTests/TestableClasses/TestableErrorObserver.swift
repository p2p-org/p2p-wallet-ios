import Foundation
import KeyAppKitCore
@testable import Onboarding

class TestableErrorObserver: ErrorObserver {
    var errors: [Error] = []

    var serviceError: [WalletMetadataServiceImpl.Error] {
        errors.compactMap { error in
            error as? WalletMetadataServiceImpl.Error
        }
    }

    func handleError(_ error: Error, config _: KeyAppKitCore.ErrorObserverConfig?) {
        errors.append(error)
    }

    func handleError(_ error: Error, userInfo _: [String: Any]?) {
        errors.append(error)
    }
}
