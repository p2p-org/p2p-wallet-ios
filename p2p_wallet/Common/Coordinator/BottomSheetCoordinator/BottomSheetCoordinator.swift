import Combine
import Foundation
import SwiftUI

@MainActor
class BottomSheetInfoCoordinator<Content: View>: Coordinator<Void> {
    let vc: UIBottomSheetHostingController<Content>
    let parentVC: UIViewController

    init(
        parentVC: UIViewController,
        rootView: Content,
        shouldIgnoresKeyboard: Bool = true
    ) {
        self.parentVC = parentVC
        vc = .init(rootView: rootView, shouldIgnoresKeyboard: shouldIgnoresKeyboard)
        vc.view.layer.cornerRadius = 20
    }

    // MARK: - Methods

    override func start() -> AnyPublisher<Void, Never> {
        parentVC.present(vc, interactiveDismissalType: .standard)
        return vc.deallocatedPublisher()
    }
}
