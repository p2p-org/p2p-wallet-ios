import Combine
import SafariServices
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

    @Injected private var bankTransferService: any BankTransferService

    init(
        userData: BankTransfer.UserData,
        navigationController: UINavigationController? = nil
    ) {
        self.navigationController = navigationController
        self.userData = userData
    }

    override func start() -> AnyPublisher<Void, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = UIBottomSheetHostingController(rootView: BankTransferInfoView(viewModel: viewModel))

        viewModel.objectWillChange
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak controller] _ in
                DispatchQueue.main.async {
                    controller?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

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

        viewModel.openProviderInfo.flatMap { url in
            let safari = SFSafariViewController(url: url)
            controller.show(safari, sender: nil)
            return safari.deallocatedPublisher()
        }.sink {}.store(in: &subscriptions)

        viewModel.openRegistration
            .flatMap { country in
                self.coordinate(to: StrigaRegistrationFirstStepCoordinator(country: country, parent: controller))
            }
            .sink { _ in }
            .store(in: &subscriptions)

        controller.view.layer.cornerRadius = 20
        navigationController.present(controller, interactiveDismissalType: .standard)
        return controller.deallocatedPublisher().prefix(1).eraseToAnyPublisher()
    }
}
