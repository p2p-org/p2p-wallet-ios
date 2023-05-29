import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver
import SafariServices

enum BankTransferInfoCoordinatorResult {
    case cancel
    case registration(country: Country)
}

final class BankTransferInfoCoordinator: Coordinator<BankTransferInfoCoordinatorResult> {

    // MARK: -

    private var navigationController: UINavigationController!

    // MARK: -

    @Injected private var bankTransferService: any BankTransferService

    init(
        navigationController: UINavigationController? = nil
    ) {
        self.navigationController = navigationController
    }

    override func start() -> AnyPublisher<BankTransferInfoCoordinatorResult, Never> {
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

        viewModel.openProviderInfo.flatMap { [weak controller] url in
            let safari = SFSafariViewController(url: url)
            controller?.show(safari, sender: nil)
            return safari.deallocatedPublisher()
        }.sink {}.store(in: &subscriptions)

        controller.view.layer.cornerRadius = 20
        navigationController.present(controller, interactiveDismissalType: .standard)
        return Publishers.Merge(
            controller.deallocatedPublisher().map { BankTransferInfoCoordinatorResult.cancel },
            viewModel.openRegistration.map { country in BankTransferInfoCoordinatorResult.registration(country: country) }
                .handleEvents(receiveOutput: { [weak controller] country in
                    controller?.dismiss(animated: true)
                })
        ).prefix(1).eraseToAnyPublisher()
    }
}
