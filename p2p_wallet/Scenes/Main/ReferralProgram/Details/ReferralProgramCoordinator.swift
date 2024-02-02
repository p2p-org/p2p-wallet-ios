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
                    activityItems: ["\(L10n.heyLetSSwapTrendyMemeCoinsWithMe) \(link)"],
                    applicationActivities: nil
                )
                vc?.present(activityVC, animated: true)
            }
            .store(in: &subscriptions)

        return result.eraseToAnyPublisher()
    }
}
