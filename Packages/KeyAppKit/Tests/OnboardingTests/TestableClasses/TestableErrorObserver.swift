//
//  File.swift
//
//
//  Created by Giang Long Tran on 23.06.2023.
//

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

    func handleError(_ error: Error) {
        errors.append(error)
    }

    func handleError(_ error: Error, userInfo _: [String: Any]?) {
        errors.append(error)
    }
}
