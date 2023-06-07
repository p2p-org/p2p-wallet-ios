import SwiftUI
import BankTransfer
import Combine
import CountriesAPI

enum StrigaRegistrationFirstStepCoordinatorResult {
    case completed
    case canceled
}

final class StrigaRegistrationFirstStepCoordinator: Coordinator<StrigaRegistrationFirstStepCoordinatorResult> {
    private let country: Country
    private let navigationController: UINavigationController

    init(country: Country, navigationController: UINavigationController) {
        self.country = country
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<StrigaRegistrationFirstStepCoordinatorResult, Never> {
        let viewModel = StrigaRegistrationFirstStepViewModel(country: country)
        let view = StrigaRegistrationFirstStepView(viewModel: viewModel)

        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.hidesBottomBarWhenPushed = true
        vc.title = L10n.stepOf(1, 3)

        viewModel.back
            .sink { [weak self] _ in
                self?.navigationController.dismiss(animated: true)
            }
            .store(in: &subscriptions)

        viewModel.chooseCountry
            .flatMap { [unowned self] in self.openChooseCountry(value: $0) }
            .sink { [weak viewModel] result in
                switch result {
                case .item(let item):
                    guard let item = item as? Country else { return }
                    viewModel?.selectedCountryOfBirth = item
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        viewModel.choosePhoneCountryCode
            .flatMap { [unowned self] in self.openChooseCountry(value: $0) }
            .sink { [weak viewModel] result in
                switch result {
                case .item(let item):
                    viewModel?.selectedPhoneCountryCode = item as? Country
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        navigationController.setViewControllers(
            [
                navigationController.viewControllers.first,
                vc
            ].compactMap { $0 },
            animated: true
        )

        return Publishers.Merge(
            vc.deallocatedPublisher()
                .map { StrigaRegistrationFirstStepCoordinatorResult.canceled },
            viewModel.openNextStep.eraseToAnyPublisher()
                .flatMap({ [unowned self] response in
                    self.coordinateToNextStep(response: response)
                    // ignoring cancel events, to not pass this event out of Coordinator
                        .filter { $0 != .canceled }
                })
                .map { result in
                    switch result {
                    case .completed:
                        return StrigaRegistrationFirstStepCoordinatorResult.completed
                    case .canceled:
                        return StrigaRegistrationFirstStepCoordinatorResult.canceled
                    }
                }
        )
        .prefix(1)
        .eraseToAnyPublisher()
    }

    private func openChooseCountry(value: Country?) -> AnyPublisher<ChooseItemCoordinatorResult, Never> {
        coordinate(to: ChooseItemCoordinator<Country>(title: L10n.selectYourCountry, controller: navigationController, service: ChooseCountryService(), chosen: value))
    }

    private func coordinateToNextStep(response: StrigaUserDetailsResponse) -> AnyPublisher<StrigaRegistrationSecondStepCoordinatorResult, Never> {
        self.coordinate(
            to: StrigaRegistrationSecondStepCoordinator(
                navigationController: self.navigationController,
                data: response
            ))
    }
}
