import SwiftUI
import Combine
import CountriesAPI

final class StrigaRegistrationFirstStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let country: Country
    private let parent: UIViewController
    private let navigationController: UINavigationController

    init(country: Country, parent: UIViewController) {
        self.country = country
        self.parent = parent
        self.navigationController = UINavigationController()
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StrigaRegistrationFirstStepViewModel(country: country)
        let view = StrigaRegistrationFirstStepView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.stepOf(1, 3)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen

        viewModel.openNextStep
            .flatMap { data in
                self.coordinate(
                    to: StrigaRegistrationSecondStepCoordinator(
                        navigationController: self.navigationController,
                        data: data
                    )
                )
            }
            .sink { }
            .store(in: &subscriptions)

        viewModel.back
            .sink { [weak self] _ in
                self?.navigationController.dismiss(animated: true)
            }
            .store(in: &subscriptions)

        viewModel.chooseCountry.flatMap { value in
            self.coordinate(to: ChooseItemCoordinator<Country>(
                title: L10n.selectYourCountry,
                controller: self.navigationController,
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

        parent.present(navigationController, animated: true)

        return Publishers.Merge(
            vc.deallocatedPublisher(),
            result.eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}
