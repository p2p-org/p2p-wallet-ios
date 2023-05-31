import SwiftUI
import Combine
import CountriesAPI
import BankTransfer

final class StrigaRegistrationSecondStepCoordinator: Coordinator<Void> {
    private let result = PassthroughSubject<Void, Never>()
    private let navigationController: UINavigationController
    private let data: StrigaUserDetailsResponse

    init(navigationController: UINavigationController, data: StrigaUserDetailsResponse) {
        self.navigationController = navigationController
        self.data = data
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = StrigaRegistrationSecondStepViewModel(data: data)
        let view = StrigaRegistrationSecondStepView(viewModel: viewModel)
        let vc = view.asViewController(withoutUIKitNavBar: false)
        vc.title = L10n.stepOf(2, 3)
        navigationController.pushViewController(vc, animated: true)

        viewModel.chooseIndustry
            .flatMap { value in
                self.coordinate(to: ChooseItemCoordinator<Industry>(
                    title: L10n.selectYourIndustry,
                    controller: self.navigationController,
                    service: ChooseIndustryService(),
                    chosen: value
                ))
            }
            .sink { [weak viewModel] result in
                switch result {
                case .item(let item):
                    viewModel?.selectedIndustry = item as? Industry
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        viewModel.chooseSourceOfFunds
            .flatMap { value in
                self.coordinate(to: ChooseItemCoordinator<StrigaSourceOfFunds>(
                    title: L10n.selectYourSourceOfFunds,
                    controller: self.navigationController,
                    service: ChooseSourceOfFundsService(),
                    chosen: value
                ))
            }
            .sink { [weak viewModel] result in
                switch result {
                case .item(let item):
                    viewModel?.selectedSourceOfFunds = item as? StrigaSourceOfFunds
                case .cancel: break
                }
            }
            .store(in: &subscriptions)

        return Publishers.Merge(
            vc.deallocatedPublisher(),
            result.eraseToAnyPublisher()
        )
        .prefix(1).eraseToAnyPublisher()
    }
}
