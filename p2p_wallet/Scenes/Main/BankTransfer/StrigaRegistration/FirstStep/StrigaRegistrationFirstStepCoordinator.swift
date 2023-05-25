import SwiftUI
import Combine
import CountriesAPI

final class StrigaRegistrationFirstStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let country: Country
    private let parent: UINavigationController

    init(country: Country, parent: UINavigationController) {
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

        viewModel.chooseCountry.flatMap { value in
            self.coordinate(to: ChooseItemCoordinator<Country>(
                title: L10n.selectYourCountry,
                controller: self.parent,
                service: ChooseCountryService(),
                chosen: value
            ))
        }.sink { [weak viewModel] result in
            switch result {
            case .item(let item):
                viewModel?.selectedCountryOfBirth = item as? Country
            case .cancel: break
            }
        }.store(in: &subscriptions)

        parent.pushViewController(vc, animated: true)

        return result.first().eraseToAnyPublisher()
    }
}
