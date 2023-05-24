import SwiftUI
import Combine

final class StrigaRegistrationFirstStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let country: String
    private let parent: UINavigationController

    init(country: String, parent: UINavigationController) {
        self.country = country
        self.parent = parent
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StrigaRegistrationFirstStepViewModel(country: country)
        let view = StrigaRegistrationFirstStepView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.stepOf(1, 3)
        vc.hidesBottomBarWhenPushed = true

        viewModel.openNextStep
            .sink { _ in
                //TODO: Open second screen
            }
            .store(in: &subscriptions)
        
        viewModel.chooseCountry
            .sink { country in
                // TODO: Open country selection
            }
            .store(in: &subscriptions)

        parent.pushViewController(vc, animated: true)

        return result.first().eraseToAnyPublisher()
    }
}
