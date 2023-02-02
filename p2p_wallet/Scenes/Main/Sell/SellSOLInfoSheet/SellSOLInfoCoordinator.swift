import Combine
import SwiftUI
import Resolver
import AnalyticsManager

final class SellSOLInfoCoordinator: Coordinator<Void> {
    @Injected private var analyticsManager: AnalyticsManager
    
    private var transition: PanelTransition?
    private var viewController: UIViewController?

    private let parentController: UIViewController
    private var subject = PassthroughSubject<Void, Never>()

    init(parentController: UIViewController) {
        self.parentController = parentController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = SellSOLInfoView { [weak self] in
            self?.analyticsManager.log(event: AmplitudeEvent.sellOnlySolNotification)
            self?.finish()
        }
        transition = PanelTransition()
        transition?.containerHeight = 428.adaptiveHeight
        let viewController = UIHostingController(rootView: view)
        viewController.view.layer.cornerRadius = 20
        viewController.transitioningDelegate = transition
        viewController.modalPresentationStyle = .custom

        transition?.dimmClicked
            .sink { [weak self] in self?.finish() }
            .store(in: &subscriptions)
        parentController.present(viewController, animated: true)
        self.viewController = viewController

        return subject.prefix(1).eraseToAnyPublisher()
    }

    private func finish() {
        self.viewController?.dismiss(animated: true)
        self.subject.send(())
    }
}
