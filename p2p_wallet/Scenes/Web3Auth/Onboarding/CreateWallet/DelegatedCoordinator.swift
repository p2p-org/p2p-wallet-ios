import Combine
import Foundation
import Onboarding
import UIKit

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
