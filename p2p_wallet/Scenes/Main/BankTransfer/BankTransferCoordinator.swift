import Combine
import Foundation
import Resolver
import AnalyticsManager
import BankTransfer
import CountriesAPI

final class BankTransferCoordinator: Coordinator<Void> {

    // MARK: -

    private var navigationController: UINavigationController!
    private var userData: BankTransfer.UserData

    // MARK: -

    @Injected private var bankTransferService: BankTransferService

    init(
        userData: BankTransfer.UserData,
        navigationController: UINavigationController? = nil
    ) {
        self.navigationController = navigationController
        self.userData = userData
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = BottomSheetController(
            rootView: BankTransferInfoView(viewModel: viewModel)
        )

        viewModel.showCountries.flatMap { val in
            self.coordinate(to: ChooseItemCoordinator<Country>(
                title: L10n.selectYourCountry,
                controller: controller,
                service: ChooseCountryService(),
                chosen: val
            ))
        }.sink { result in
            switch result {
            case .item(let item):
                viewModel.setCountry(item as! Country)
            case .cancel: break
            }
        }.store(in: &subscriptions)

        // TODO: Not sure what kind of navigaiton should be here
        viewModel.openRegistration
            .flatMap { country in
                self.coordinate(to: StrigaRegistrationFirstStepCoordinator(country: country, parent: controller))
            }
            .sink { _ in }
            .store(in: &subscriptions)

        navigationController?.present(controller, animated: true)
        return controller.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}
