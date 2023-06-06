import Combine
import Foundation
import Resolver

final class StrigaOTPSuccessCoordinator: Coordinator<Void> {

    @Injected private var helpLauncher: HelpCenterLauncher

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let view = StrigaOTPCompletedView(
            image: .thumbsupImage,
            title: L10n.thankYou,
            subtitle: L10n.TheLastStepIsDocumentAndSelfieVerification.thisIsAOneTimeProcedureToEnsureSafetyOfYourAccount,
            actionTitle: L10n.continue,
            onAction:  { [weak self] in
                self?.navigationController.popToRootViewController(animated: true)
            }) { [weak self] in
                self?.helpLauncher.launch()
            }

        let controller = view.asViewController(withoutUIKitNavBar: false)
        controller.navigationItem.hidesBackButton = true
        controller.hidesBottomBarWhenPushed = true
        navigationController.setViewControllers([
            navigationController.viewControllers.first,
            controller
        ].compactMap { $0 }, animated: true)

        return controller
            .deallocatedPublisher()
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
