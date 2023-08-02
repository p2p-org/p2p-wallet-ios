//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import KeyAppKitCore

struct MockErrorObservable: ErrorObserver {
    func handleError(_ error: Error, userInfo _: [String: Any]?) {
        print(error)
    }

    func handleError(_ error: Error, config _: KeyAppKitCore.ErrorObserverConfig?) {
        print(error)
    }
}
