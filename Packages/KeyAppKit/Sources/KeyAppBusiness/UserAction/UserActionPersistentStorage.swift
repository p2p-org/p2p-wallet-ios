//
//  File.swift
//
//
//  Created by Giang Long Tran on 30.03.2023.
//

import Foundation
import KeyAppKitCore

public protocol UserActionPersistentStorage: AnyObject {
    func save(in table: String, data: Data)

    func restore(table: String) -> Data?
}

public class UserActionPersistentStorageWithUserDefault: UserActionPersistentStorage {
    let userDefault: UserDefaults?
    let errorObserver: ErrorObserver

    public init(errorObserver: ErrorObserver) {
        userDefault = .init(suiteName: "UserActionPersistentStorage")
        self.errorObserver = errorObserver

        if userDefault == nil {
            errorObserver.handleError(UserActionError(
                domain: "UserActionPersistentStorageWithUserDefault",
                code: 1,
                reason: "Can not access to user default"
            ))
        }
    }

    public func save(in table: String, data: Data) {
        userDefault?.setValue(data, forKey: table)
    }

    public func restore(table: String) -> Data? {
        userDefault?.data(forKey: table)
    }
}
