// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

enum CoordinatorError: Error {
    case isAlreadyStarted
}

protocol AbstractCoordinator {
    @discardableResult
    func start() throws -> UIViewController

    @discardableResult
    func start(_ completion: ((Any) -> Void)?) throws -> UIViewController
}

extension AbstractCoordinator {
    func start() throws -> UIViewController { try start(nil) }
}
