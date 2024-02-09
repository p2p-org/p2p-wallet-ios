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

        viewModel.openShare
            .sink { [weak vc] link in
                let activityVC = UIActivityViewController(
                    activityItems: [link],
                    applicationActivities: nil
                )
                vc?.present(activityVC, animated: true)
            }
            .store(in: &subscriptions)

        viewModel.openTerms
            .sink { [weak self] url in
                guard let self else { return }
                coordinate(to: TermsAndConditionsCoordinator(navigationController: self.navigationController, url: url))
                    .sink(receiveValue: {}).store(in: &self.subscriptions)
            }
            .store(in: &subscriptions)

        return result.eraseToAnyPublisher()
    }
}
