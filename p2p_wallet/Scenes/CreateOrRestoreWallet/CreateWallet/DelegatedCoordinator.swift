// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Combine
import Foundation
import Onboarding

@MainActor
class DelegatedCoordinator<S: State> {
    var subscriptions = [AnyCancellable]()

    let stateMachine: HierarchyStateMachine<S>
    var rootViewController: UIViewController?

    init(stateMachine: HierarchyStateMachine<S>) {
        self.stateMachine = stateMachine
    }

    func buildViewController(for _: S) -> UIViewController? {
        fatalError()
    }
}
