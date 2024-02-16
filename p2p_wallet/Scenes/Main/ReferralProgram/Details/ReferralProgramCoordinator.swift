import Combine
import SwiftUI
import UIKit

final class ReferralProgramCoordinator: Coordinator<Void> {
    private let navigationController: UINavigationController
    private let result = PassthroughSubject<Void, Never>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = ReferralProgramViewModel()
        let view = ReferralProgramView(viewModel: viewModel)
        let vc = UIHostingController(rootView: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)

        viewModel.bridge.actionPublisher
            .sink { [weak self, weak vc] action in
                guard let self, let vc else { return }
                switch action {
                case let .openShare(string):
                    let activityVC = UIActivityViewController(
                        activityItems: [string],
                        applicationActivities: nil
                    )
                    vc.present(activityVC, animated: true)
                case let .openTerms(url):
                    coordinate(to: TermsAndConditionsCoordinator(
                        navigationController: self.navigationController,
                        url: url
                    ))
                    .sink(receiveValue: {}).store(in: &self.subscriptions)
                case .openSwap:
                    coordinate(to: JupiterSwapCoordinator(
                        navigationController: self.navigationController,
                        params: .init(dismissAfterCompletion: true, openKeyboardOnStart: true, source: .deeplink)
                    ))
                    .sink(receiveValue: {}).store(in: &self.subscriptions)
                }
            }
            .store(in: &subscriptions)

        return result.eraseToAnyPublisher()
    }
}
