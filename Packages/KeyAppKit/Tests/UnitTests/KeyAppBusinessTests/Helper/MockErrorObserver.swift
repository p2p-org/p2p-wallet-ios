//
//  File.swift
//
//
//  Created by Giang Long Tran on 12.03.2023.
//

import Foundation
import KeyAppKitCore

struct MockErrorObservable: ErrorObserver {
    func handleError(_ error: Error) {
        print(error)
    }
}
