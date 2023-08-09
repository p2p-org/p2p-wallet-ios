import BankTransfer
import Combine
import CountriesAPI
import SwiftUI

enum StrigaRegistrationFirstStepCoordinatorResult {
    case completed
    case canceled
}

final class StrigaRegistrationFirstStepCoordinator: Coordinator<StrigaRegistrationFirstStepCoordinatorResult> {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<StrigaRegistrationFirstStepCoordinatorResult, Never> {
        let viewModel = StrigaRegistrationFirstStepViewModel()
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
            .flatMap { [unowned self] in
                coordinate(to: ChooseItemCoordinator<Country>(
                    title: L10n.selectYourCountry,
                    controller: navigationController,
                    service: ChooseCountryService(),
                    chosen: $0
                ))
            }
            .sink { [weak viewModel] result in
                switch result {
                case let .item(item):
                    guard let item = item as? Country else { return }
                    viewModel?.selectedCountryOfBirth = item
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        viewModel.choosePhoneCountryCode
            .flatMap { [unowned self] in
                coordinate(to: ChooseItemCoordinator<PhoneCodeItem>(
                    title: L10n.selectYourCountry,
                    controller: navigationController,
                    service: ChoosePhoneCodeService(),
                    chosen: PhoneCodeItem(country: $0)
                ))
            }
            .sink { [weak viewModel] result in
                switch result {
                case let .item(item):
                    guard let item = item as? PhoneCodeItem else { return }
                    viewModel?.selectedPhoneCountryCode = item.country
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        // We know we have come from BankTransferInfoCoordinator. We need to remove in from hierarchy
        var newVCs = Array(navigationController.viewControllers.dropLast())
        newVCs.append(vc)
        navigationController.setViewControllers(newVCs, animated: true)

        return Publishers.Merge(
            vc.deallocatedPublisher()
                .map { StrigaRegistrationFirstStepCoordinatorResult.canceled },
            viewModel.openNextStep.eraseToAnyPublisher()
                .flatMap { [unowned self] response in
                    self.coordinateToNextStep(response: response)
                        // ignoring cancel events, to not pass this event out of Coordinator
                            .filter { $0 != .canceled }
                }
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

    private func coordinateToNextStep(response: StrigaUserDetailsResponse)
    -> AnyPublisher<StrigaRegistrationSecondStepCoordinatorResult, Never> {
        coordinate(
            to: StrigaRegistrationSecondStepCoordinator(
                navigationController: navigationController,
                data: response
            )
        )
    }
}
