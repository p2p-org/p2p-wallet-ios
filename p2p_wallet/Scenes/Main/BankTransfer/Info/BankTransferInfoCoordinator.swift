import BankTransfer
import Combine
import CountriesAPI
import Foundation
import Resolver
import SafariServices

enum BankTransferInfoCoordinatorResult {
    case canceled
    case completed
}

final class BankTransferInfoCoordinator: Coordinator<BankTransferInfoCoordinatorResult> {

    // MARK: -

    private var viewController: UINavigationController

    // MARK: -

    @Injected private var bankTransferService: any BankTransferService

    init(
        viewController: UINavigationController
    ) {
        self.viewController = viewController
    }

    override func start() -> AnyPublisher<BankTransferInfoCoordinatorResult, Never> {
        let viewModel = BankTransferInfoViewModel()
        let controller = UIBottomSheetHostingController(
            rootView: BankTransferInfoView(viewModel: viewModel),
            ignoresKeyboard: true
        )

        viewModel.objectWillChange
            .delay(for: 0.01, scheduler: RunLoop.main)
            .sink { [weak controller] _ in
                DispatchQueue.main.async {
                    controller?.updatePresentationLayout(animated: true)
                }
            }
            .store(in: &subscriptions)

        viewModel.showCountries.flatMap { [unowned self, unowned controller] val in
            self.coordinate(to: ChooseItemCoordinator<Country>(
                title: L10n.selectYourCountry,
                controller: controller,
                service: ChooseCountryService(),
                chosen: val,
                showDoneButton: true
            ))
        }.sink { [weak viewModel] result in
            switch result {
            case .item(let item):
                viewModel?.setCountry(item as! Country)
            case .cancel: break
            }
        }.store(in: &subscriptions)

        viewModel.openProviderInfo.flatMap { [weak controller] url in
            let safari = SFSafariViewController(url: url)
            controller?.show(safari, sender: nil)
            return safari.deallocatedPublisher()
        }.sink {}.store(in: &subscriptions)

        controller.view.layer.cornerRadius = 20
        viewController.present(controller, interactiveDismissalType: .standard)

        return Publishers.Merge(
            // Ignore deallocation event if open registration triggered
            Publishers.Merge(
                controller.deallocatedPublisher().map { true },
                viewModel.openRegistration.map { _ in false }
            )
                .prefix(1)
                .filter { $0 }
                .map { _ in BankTransferInfoCoordinatorResult.canceled }
                .eraseToAnyPublisher(),
            viewModel.openRegistration
                .handleEvents(receiveOutput: { [weak controller] _ in
                    controller?.dismiss(animated: true)
                })
                .flatMap({ [unowned self] country in
                    self.coordinate(
                        to: StrigaRegistrationFirstStepCoordinator(
                            country: country,
                            navigationController: self.viewController
                        )
                    )
                })
                .map { result in
                    switch result {
                    case .completed:
                        return BankTransferInfoCoordinatorResult.completed
                    case .canceled:
                        return BankTransferInfoCoordinatorResult.canceled
                    }
                }
        )
            .prefix(1)
            .eraseToAnyPublisher()
    }
}
